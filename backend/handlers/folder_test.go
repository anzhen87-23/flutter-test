package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"personal-notes-backend/handlers"
	"personal-notes-backend/middleware"
	"personal-notes-backend/models"

	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupFolderRouter(t *testing.T) (*gin.Engine, *gorm.DB) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	err = db.AutoMigrate(&models.User{}, &models.Note{}, &models.Folder{})
	assert.NoError(t, err)

	r := gin.New()
	folderHandler := handlers.NewFolderHandler(db)

	auth := r.Group("/api/folders")
	auth.Use(middleware.AuthMiddleware())
	auth.GET("", folderHandler.ListFolders)
	auth.GET("/:id", folderHandler.GetFolder)
	auth.POST("", folderHandler.CreateFolder)
	auth.PUT("/:id", folderHandler.UpdateFolder)
	auth.DELETE("/:id", folderHandler.DeleteFolder)

	return r, db
}

func TestCreateFolder_Success(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	body := map[string]string{"name": "Work Notes"}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/folders", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, "Work Notes", data["name"])
}

func TestCreateFolder_DuplicateName(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Folder{UserID: userID, Name: "Work"})

	body := map[string]string{"name": "Work"}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/folders", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusConflict, w.Code)
}

func TestListFolders_Success(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Folder{UserID: userID, Name: "A"})
	db.Create(&models.Folder{UserID: userID, Name: "B"})

	req, _ := http.NewRequest("GET", "/api/folders", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].([]interface{})
	assert.Len(t, data, 2)
}

func TestGetFolder_Success(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Folder{UserID: userID, Name: "MyFolder"})

	req, _ := http.NewRequest("GET", "/api/folders/1", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestUpdateFolder_Success(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Folder{UserID: userID, Name: "Old Name"})

	body := map[string]string{"name": "New Name"}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/folders/1", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, "New Name", data["name"])
}

func TestDeleteFolder_Success(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Folder{UserID: userID, Name: "ToDelete"})

	req, _ := http.NewRequest("DELETE", "/api/folders/1", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var count int64
	db.Model(&models.Folder{}).Where("id = ?", 1).Count(&count)
	assert.Equal(t, int64(0), count)
}

func TestDeleteFolder_MovesNotesToUncategorized(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	folder := models.Folder{UserID: userID, Name: "ToDelete"}
	db.Create(&folder)

	// 文件夹内有笔记
	note := models.Note{UserID: userID, Title: "Note", FolderID: &folder.ID}
	db.Create(&note)

	req, _ := http.NewRequest("DELETE", "/api/folders/1", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	// 验证笔记的 folder_id 被设置为 nil
	var updatedNote models.Note
	db.First(&updatedNote, note.ID)
	assert.Nil(t, updatedNote.FolderID)
}

func TestListFolders_IncludesNoteCount(t *testing.T) {
	r, db := setupFolderRouter(t)
	userID := createTestUser(t, db)

	folder := models.Folder{UserID: userID, Name: "Work"}
	db.Create(&folder)

	// 3条笔记在这个文件夹
	for i := 0; i < 3; i++ {
		db.Create(&models.Note{UserID: userID, Title: "N", FolderID: &folder.ID})
	}

	req, _ := http.NewRequest("GET", "/api/folders", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].([]interface{})
	f := data[0].(map[string]interface{})
	assert.Equal(t, float64(3), f["note_count"])
}

func TestGetFolder_NoAuth(t *testing.T) {
	r, _ := setupFolderRouter(t)

	req, _ := http.NewRequest("GET", "/api/folders/1", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

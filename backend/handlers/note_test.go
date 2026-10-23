package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"personal-notes-backend/middleware"
	"personal-notes-backend/models"
	"personal-notes-backend/utils"

	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"personal-notes-backend/handlers"
)

func setupNoteRouter(t *testing.T) (*gin.Engine, *gorm.DB) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	err = db.AutoMigrate(&models.User{}, &models.Note{}, &models.Folder{})
	assert.NoError(t, err)

	r := gin.New()
	noteHandler := handlers.NewNoteHandler(db)

	auth := r.Group("/api/notes")
	auth.Use(middleware.AuthMiddleware())
	auth.GET("", noteHandler.ListNotes)
	auth.GET("/:id", noteHandler.GetNote)
	auth.POST("", noteHandler.CreateNote)
	auth.PUT("/:id", noteHandler.UpdateNote)
	auth.DELETE("/:id", noteHandler.DeleteNote)

	return r, db
}

func authHeader(t *testing.T, userID uint) string {
	token, err := utils.GenerateToken(userID)
	assert.NoError(t, err)
	return "Bearer " + token
}

func createTestUser(t *testing.T, db *gorm.DB) uint {
	user := models.User{Username: "testuser", Password: "hashed"}
	db.Create(&user)
	return user.ID
}

func TestCreateNote_Success(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	body := map[string]interface{}{
		"title":   "Test Note",
		"content": "Hello World",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/notes", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, "Test Note", data["title"])
	assert.Equal(t, float64(userID), data["user_id"])
}

func TestCreateNote_WithTitleTooLong(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	// 201字符
	longTitle := ""
	for i := 0; i < 201; i++ {
		longTitle += "a"
	}

	body := map[string]interface{}{
		"title":   longTitle,
		"content": "test",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/notes", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestCreateNote_NoAuth(t *testing.T) {
	r, _ := setupNoteRouter(t)

	body := map[string]interface{}{"title": "Test", "content": "test"}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/notes", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestListNotes_Success(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	// 创建3条笔记
	for i := 1; i <= 3; i++ {
		db.Create(&models.Note{UserID: userID, Title: "Note " + string(rune('0'+i)), Content: "content"})
	}

	req, _ := http.NewRequest("GET", "/api/notes", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	notes := data["notes"].([]interface{})
	assert.Len(t, notes, 3)
	assert.Equal(t, float64(3), data["total"])
}

func TestListNotes_Pagination(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	for i := 0; i < 25; i++ {
		db.Create(&models.Note{UserID: userID, Title: "Note", Content: "content"})
	}

	req, _ := http.NewRequest("GET", "/api/notes?page=2&page_size=10", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	notes := data["notes"].([]interface{})
	assert.Len(t, notes, 10)
}

func TestGetNote_Success(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	note := models.Note{UserID: userID, Title: "Test", Content: "Hello"}
	db.Create(&note)

	req, _ := http.NewRequest("GET", "/api/notes/1", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestGetNote_NotFound(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	req, _ := http.NewRequest("GET", "/api/notes/999", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestGetNote_OtherUser(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)
	otherUser := models.User{Username: "other", Password: "x"}
	db.Create(&otherUser)

	// userID 创建笔记
	db.Create(&models.Note{UserID: userID, Title: "Private", Content: "x"})

	// otherUser 尝试访问
	req, _ := http.NewRequest("GET", "/api/notes/1", nil)
	token, _ := utils.GenerateToken(otherUser.ID)
	req.Header.Set("Authorization", "Bearer "+token)

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusNotFound, w.Code)
}

func TestUpdateNote_Success(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Note{UserID: userID, Title: "Old", Content: "Old"})

	body := map[string]string{"title": "New Title"}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/notes/1", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, "New Title", data["title"])
}

func TestDeleteNote_Success(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	db.Create(&models.Note{UserID: userID, Title: "ToDelete", Content: "x"})

	req, _ := http.NewRequest("DELETE", "/api/notes/1", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	// 验证已删除
	var count int64
	db.Model(&models.Note{}).Where("id = ?", 1).Count(&count)
	assert.Equal(t, int64(0), count)
}

func TestCreateNote_WithFolder(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	folder := models.Folder{UserID: userID, Name: "My Folder"}
	db.Create(&folder)

	body := map[string]interface{}{
		"title":     "Note in folder",
		"content":   "test",
		"folder_id": folder.ID,
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/notes", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusCreated, w.Code)
}

func TestListNotes_FilterByFolder(t *testing.T) {
	r, db := setupNoteRouter(t)
	userID := createTestUser(t, db)

	folder := models.Folder{UserID: userID, Name: "Work"}
	db.Create(&folder)

	// 2条在文件夹，1条不在
	db.Create(&models.Note{UserID: userID, Title: "A", FolderID: &folder.ID})
	db.Create(&models.Note{UserID: userID, Title: "B", FolderID: &folder.ID})
	db.Create(&models.Note{UserID: userID, Title: "C"})

	req, _ := http.NewRequest("GET", "/api/notes?folder_id=1", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	notes := data["notes"].([]interface{})
	assert.Len(t, notes, 2)
}

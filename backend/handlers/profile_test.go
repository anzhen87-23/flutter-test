package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"personal-notes-backend/handlers"
	"personal-notes-backend/middleware"
	"personal-notes-backend/models"
	"personal-notes-backend/utils"

	"github.com/stretchr/testify/assert"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func setupProfileRouter(t *testing.T) (*gin.Engine, *gorm.DB) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	err = db.AutoMigrate(
		&models.User{},
		&models.Avatar{},
		&models.VerificationCode{},
	)
	assert.NoError(t, err)

	r := gin.New()
	profileHandler := handlers.NewProfileHandler(db)

	auth := r.Group("/api/profile")
	auth.Use(middleware.AuthMiddleware())
	auth.GET("", profileHandler.GetProfile)
	auth.PUT("/nickname", profileHandler.UpdateNickname)
	auth.PUT("/birthday", profileHandler.UpdateBirthday)
	auth.PUT("/phone", profileHandler.UpdatePhone)
	auth.PUT("/email", profileHandler.UpdateEmail)
	auth.PUT("/password", profileHandler.ChangePassword)

	return r, db
}

func createFullUser(t *testing.T, db *gorm.DB, phone, password string) uint {
	hashedPassword, _ := utils.HashPassword(password)
	user := models.User{
		Username: "testuser",
		Phone:    &phone,
		Password: hashedPassword,
		Nickname: "OldNick",
	}
	db.Create(&user)
	return user.ID
}

func TestGetProfile_Success(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	req, _ := http.NewRequest("GET", "/api/profile", nil)
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	data := resp["data"].(map[string]interface{})
	assert.Equal(t, "OldNick", data["nickname"])
	assert.Equal(t, "138****8000", data["phone"]) // 手机号脱敏
}

func TestUpdateNickname_Success(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	body := map[string]string{"nickname": "NewNick"}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/nickname", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	// 验证已更新
	var user models.User
	db.First(&user, userID)
	assert.Equal(t, "NewNick", user.Nickname)
}

func TestUpdateNickname_Empty(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	body := map[string]string{}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/nickname", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestUpdateBirthday_Success(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	birthday := time.Date(1990, 5, 15, 0, 0, 0, 0, time.UTC)
	body := map[string]interface{}{"birthday": birthday.Format(time.RFC3339)}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/birthday", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var user models.User
	db.First(&user, userID)
	assert.NotNil(t, user.Birthday)
}

func TestUpdatePhone_Success(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	// 创建验证码
	code, _ := utils.CreateVerificationCode(db, "13900009000", "verify_phone")

	body := map[string]string{
		"new_phone": "13900009000",
		"code":      code,
		"password":  "123456",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	var user models.User
	db.First(&user, userID)
	assert.Equal(t, "13900009000", *user.Phone)
}

func TestUpdatePhone_WrongPassword(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	code, _ := utils.CreateVerificationCode(db, "13900009000", "verify_phone")

	body := map[string]string{
		"new_phone": "13900009000",
		"code":      code,
		"password":  "654321", // 错误密码
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestUpdateEmail_Success(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	code, _ := utils.CreateVerificationCode(db, "new@example.com", "verify_email")

	body := map[string]string{
		"new_email": "new@example.com",
		"code":      code,
		"password":  "123456",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/email", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestChangePassword_Success(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"old_password": "123456",
		"new_password": "654321",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/password", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	// 验证新密码可以登录
	var user models.User
	db.First(&user, userID)
	assert.True(t, utils.CheckPassword("654321", user.Password))
}

func TestChangePassword_WrongOldPassword(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"old_password": "999999",
		"new_password": "654321",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/password", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestChangePassword_SameAsOld(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"old_password": "123456",
		"new_password": "123456",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/password", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestChangePassword_InvalidFormat(t *testing.T) {
	r, db := setupProfileRouter(t)
	userID := createFullUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"old_password": "123456",
		"new_password": "abc", // 非6位数字
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("PUT", "/api/profile/password", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", authHeader(t, userID))

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"personal-notes-backend/handlers"
	"personal-notes-backend/models"
	"personal-notes-backend/utils"

	"github.com/stretchr/testify/assert"
)

// setupTestRouter 创建测试用的路由和数据库
func setupTestRouter(t *testing.T) (*gin.Engine, *gorm.DB) {
	gin.SetMode(gin.TestMode)
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	err = db.AutoMigrate(
		&models.User{},
		&models.Note{},
		&models.Folder{},
		&models.Avatar{},
		&models.VerificationCode{},
	)
	assert.NoError(t, err)

	r := gin.New()
	authHandler := handlers.NewAuthHandler(db)

	auth := r.Group("/api/auth")
	auth.POST("/send-code", authHandler.SendCode)
	auth.POST("/register/phone", authHandler.RegisterByPhone)
	auth.POST("/register/email", authHandler.RegisterByEmail)
	auth.POST("/login", authHandler.Login)
	auth.POST("/reset-password", authHandler.ResetPassword)

	return r, db
}

// createUser 创建测试用户并返回JWT Token
func createUser(t *testing.T, db *gorm.DB, phone, password string) (uint, string) {
	hashedPassword, err := utils.HashPassword(password)
	assert.NoError(t, err)
	user := models.User{
		Username: utils.GenerateUsername(phone),
		Phone:    &phone,
		Password: hashedPassword,
		Nickname: "TestUser",
	}
	db.Create(&user)
	token, err := utils.GenerateToken(user.ID)
	assert.NoError(t, err)
	return user.ID, token
}

func TestSendCode_Success(t *testing.T) {
	r, _ := setupTestRouter(t)

	body := map[string]string{
		"target": "13800008000",
		"type":   "register",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/send-code", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, float64(200), resp["code"])
}

func TestSendCode_InvalidTarget(t *testing.T) {
	r, _ := setupTestRouter(t)

	body := map[string]string{
		"target": "invalid",
		"type":   "register",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/send-code", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestSendCode_InvalidType(t *testing.T) {
	r, _ := setupTestRouter(t)

	body := map[string]string{
		"target": "13800008000",
		"type":   "invalid_type",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/send-code", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRegisterByPhone_Success(t *testing.T) {
	r, db := setupTestRouter(t)

	// 先发送验证码
	code, _ := utils.CreateVerificationCode(db, "13800008000", "register")

	body := map[string]string{
		"phone":    "13800008000",
		"code":     code,
		"password": "123456",
		"nickname": "TestUser",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, float64(200), resp["code"])
	assert.NotNil(t, resp["data"])
	data := resp["data"].(map[string]interface{})
	assert.NotNil(t, data["token"])
	assert.NotNil(t, data["user"])
}

func TestRegisterByPhone_InvalidPassword(t *testing.T) {
	r, db := setupTestRouter(t)

	code, _ := utils.CreateVerificationCode(db, "13800008000", "register")

	body := map[string]string{
		"phone":    "13800008000",
		"code":     code,
		"password": "abcdef", // 非6位数字
		"nickname": "Test",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRegisterByPhone_InvalidPhone(t *testing.T) {
	r, db := setupTestRouter(t)

	code, _ := utils.CreateVerificationCode(db, "12345", "register")

	body := map[string]string{
		"phone":    "12345",
		"code":     code,
		"password": "123456",
		"nickname": "Test",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRegisterByPhone_WrongCode(t *testing.T) {
	r, _ := setupTestRouter(t)

	body := map[string]string{
		"phone":    "13800008000",
		"code":     "000000",
		"password": "123456",
		"nickname": "Test",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestRegisterByPhone_DuplicatePhone(t *testing.T) {
	r, db := setupTestRouter(t)

	// 创建已存在的用户
	createUser(t, db, "13800008000", "123456")

	code, _ := utils.CreateVerificationCode(db, "13800008000", "register")

	body := map[string]string{
		"phone":    "13800008000",
		"code":     code,
		"password": "654321",
		"nickname": "Test2",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusConflict, w.Code)
}

func TestLogin_Success(t *testing.T) {
	r, db := setupTestRouter(t)
	createUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"account":  "13800008000",
		"password": "123456",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.NotNil(t, resp["data"])
	data := resp["data"].(map[string]interface{})
	assert.NotNil(t, data["token"])
}

func TestLogin_ByEmail(t *testing.T) {
	r, db := setupTestRouter(t)

	email := "test@example.com"
	hashedPassword, _ := utils.HashPassword("123456")
	user := models.User{
		Username: "testuser",
		Email:    &email,
		Password: hashedPassword,
	}
	db.Create(&user)

	body := map[string]string{
		"account":  email,
		"password": "123456",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}

func TestLogin_WrongPassword(t *testing.T) {
	r, db := setupTestRouter(t)
	createUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"account":  "13800008000",
		"password": "654321",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestLogin_NonExistentUser(t *testing.T) {
	r, _ := setupTestRouter(t)

	body := map[string]string{
		"account":  "13800008000",
		"password": "123456",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusUnauthorized, w.Code)
}

func TestLogin_InvalidPasswordFormat(t *testing.T) {
	r, db := setupTestRouter(t)
	createUser(t, db, "13800008000", "123456")

	body := map[string]string{
		"account":  "13800008000",
		"password": "abc",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusBadRequest, w.Code)
}

func TestResetPassword_Success(t *testing.T) {
	r, db := setupTestRouter(t)
	createUser(t, db, "13800008000", "123456")

	code, _ := utils.CreateVerificationCode(db, "13800008000", "reset_password")

	body := map[string]string{
		"account":      "13800008000",
		"code":         code,
		"new_password": "654321",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/reset-password", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)

	// 验证新密码可以登录
	loginBody := map[string]string{
		"account":  "13800008000",
		"password": "654321",
	}
	loginJSON, _ := json.Marshal(loginBody)
	loginReq, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(loginJSON))
	loginReq.Header.Set("Content-Type", "application/json")
	loginW := httptest.NewRecorder()
	r.ServeHTTP(loginW, loginReq)
	assert.Equal(t, http.StatusOK, loginW.Code)
}

func TestRegisterByEmail_Success(t *testing.T) {
	r, db := setupTestRouter(t)

	code, _ := utils.CreateVerificationCode(db, "new@example.com", "register")

	body := map[string]string{
		"email":    "new@example.com",
		"code":     code,
		"password": "123456",
		"nickname": "EmailUser",
	}
	jsonBody, _ := json.Marshal(body)

	req, _ := http.NewRequest("POST", "/api/auth/register/email", bytes.NewBuffer(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
	var resp map[string]interface{}
	json.Unmarshal(w.Body.Bytes(), &resp)
	assert.Equal(t, float64(200), resp["code"])
}

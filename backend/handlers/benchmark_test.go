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
	"personal-notes-backend/middleware"
	"personal-notes-backend/models"
	"personal-notes-backend/utils"
)

// setupBenchmarkRouter 创建基准测试路由
func setupBenchmarkRouter(b *testing.B) (*gin.Engine, *gorm.DB, string) {
	gin.SetMode(gin.TestMode)
	db, _ := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	db.AutoMigrate(&models.User{}, &models.Note{}, &models.Folder{}, &models.VerificationCode{})

	r := gin.New()
	authHandler := handlers.NewAuthHandler(db)
	noteHandler := handlers.NewNoteHandler(db)

	auth := r.Group("/api/auth")
	auth.POST("/login", authHandler.Login)
	auth.POST("/register/phone", authHandler.RegisterByPhone)

	notes := r.Group("/api/notes")
	notes.Use(middleware.AuthMiddleware())
	notes.GET("", noteHandler.ListNotes)
	notes.POST("", noteHandler.CreateNote)

	// 创建测试用户
	hashedPassword, _ := utils.HashPassword("123456")
	user := models.User{
		Username: "benchuser",
		Phone:    strPtr("13800008000"),
		Password: hashedPassword,
	}
	db.Create(&user)
	token, _ := utils.GenerateToken(user.ID)

	return r, db, token
}

func strPtr(s string) *string { return &s }

// BenchmarkLogin 登录接口性能
func BenchmarkLogin(b *testing.B) {
	r, _, _ := setupBenchmarkRouter(b)

	body := map[string]string{
		"account":  "13800008000",
		"password": "123456",
	}
	jsonBody, _ := json.Marshal(body)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("POST", "/api/auth/login", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
	}
}

// BenchmarkListNotes 笔记列表性能
func BenchmarkListNotes(b *testing.B) {
	r, db, token := setupBenchmarkRouter(b)

	// 预创建100条笔记
	for i := 0; i < 100; i++ {
		db.Create(&models.Note{
			UserID:  1,
			Title:   "Benchmark Note",
			Content: "Content for benchmark testing",
		})
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("GET", "/api/notes", nil)
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
	}
}

// BenchmarkCreateNote 创建笔记性能
func BenchmarkCreateNote(b *testing.B) {
	r, _, token := setupBenchmarkRouter(b)

	body := map[string]string{
		"title":   "New Note",
		"content": "Benchmark content",
	}
	jsonBody, _ := json.Marshal(body)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		req, _ := http.NewRequest("POST", "/api/notes", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
	}
}

// BenchmarkRegisterByPhone 手机注册性能
func BenchmarkRegisterByPhone(b *testing.B) {
	r, db, _ := setupBenchmarkRouter(b)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		phone := "1380000" + padLeft(i, 4)
		code, _ := utils.CreateVerificationCode(db, phone, "register")

		body := map[string]string{
			"phone":    phone,
			"code":     code,
			"password": "123456",
			"nickname": "BenchUser",
		}
		jsonBody, _ := json.Marshal(body)

		req, _ := http.NewRequest("POST", "/api/auth/register/phone", bytes.NewBuffer(jsonBody))
		req.Header.Set("Content-Type", "application/json")
		w := httptest.NewRecorder()
		r.ServeHTTP(w, req)
	}
}

func padLeft(n, width int) string {
	s := ""
	for n > 0 || len(s) < width {
		s = string(rune('0'+n%10)) + s
		n /= 10
	}
	return s
}

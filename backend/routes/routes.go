package routes

import (
	"log"
	"os"
	"path/filepath"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/handlers"
	"personal-notes-backend/middleware"
)

// getUploadDir 获取头像上传目录的绝对路径（与 handlers 包中保持一致）
func getUploadDir() string {
	if dir := os.Getenv("UPLOAD_DIR"); dir != "" {
		return dir
	}
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("[routes] 获取可执行文件路径失败: %v, 回退到 CWD", err)
		return "uploads/avatars"
	}
	return filepath.Join(filepath.Dir(exePath), "uploads", "avatars")
}

// getNoteUploadDir 获取笔记图片上传目录的绝对路径
func getNoteUploadDir() string {
	if dir := os.Getenv("NOTES_UPLOAD_DIR"); dir != "" {
		return dir
	}
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("[routes] 获取可执行文件路径失败: %v, 回退到 CWD", err)
		return "uploads/notes"
	}
	return filepath.Join(filepath.Dir(exePath), "uploads", "notes")
}

// SetupRouter 配置所有路由
func SetupRouter(db *gorm.DB) *gin.Engine {
	r := gin.Default()

	// 使用 CORS 中间件
	r.Use(middleware.CORS())

	// 创建处理器
	authHandler := handlers.NewAuthHandler(db)
	noteHandler := handlers.NewNoteHandler(db)
	folderHandler := handlers.NewFolderHandler(db)
	profileHandler := handlers.NewProfileHandler(db)

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

	// 静态文件服务：头像上传目录
	// 使用绝对路径，确保无论 CWD 在哪都能正确访问
	uploadDir := getUploadDir()
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		log.Printf("[routes] 创建上传目录失败: %v", err)
	} else {
		log.Printf("[routes] 头像静态服务已挂载: /uploads/avatars -> %s", uploadDir)
		r.Static("/uploads/avatars", uploadDir)
	}

	// 静态文件服务：笔记图片上传目录
	noteUploadDir := getNoteUploadDir()
	if err := os.MkdirAll(noteUploadDir, 0755); err != nil {
		log.Printf("[routes] 创建笔记图片目录失败: %v", err)
	} else {
		log.Printf("[routes] 笔记图片静态服务已挂载: /uploads/notes -> %s", noteUploadDir)
		r.Static("/uploads/notes", noteUploadDir)
	}

	// API 路由组
	api := r.Group("/api")

	// 认证路由（无需登录）
	auth := api.Group("/auth")
	{
		auth.POST("/send-code", authHandler.SendCode)
		auth.POST("/register/phone", authHandler.RegisterByPhone)
		auth.POST("/register/email", authHandler.RegisterByEmail)
		auth.POST("/login", authHandler.Login)
		auth.POST("/reset-password", authHandler.ResetPassword)
	}

	// 需要认证的路由
	authenticated := api.Group("")
	authenticated.Use(middleware.AuthMiddleware())
	{
		// 笔记 CRUD
		notes := authenticated.Group("/notes")
		{
			notes.GET("", noteHandler.ListNotes)
			notes.GET("/:id", noteHandler.GetNote)
			notes.POST("", noteHandler.CreateNote)
			notes.PUT("/:id", noteHandler.UpdateNote)
			notes.DELETE("/:id", noteHandler.DeleteNote)
			notes.POST("/upload-image", noteHandler.UploadNoteImage)
		}

		// 笔记图片管理（独立路由，避免与 /notes/:id 冲突）
		authenticated.DELETE("/note-images/:filename", noteHandler.DeleteNoteImage)

		// 文件夹 CRUD
		folders := authenticated.Group("/folders")
		{
			folders.GET("", folderHandler.ListFolders)
			folders.GET("/:id", folderHandler.GetFolder)
			folders.POST("", folderHandler.CreateFolder)
			folders.PUT("/:id", folderHandler.UpdateFolder)
			folders.DELETE("/:id", folderHandler.DeleteFolder)
		}

		// 个人信息
		profile := authenticated.Group("/profile")
		{
			profile.GET("", profileHandler.GetProfile)
			profile.PUT("/nickname", profileHandler.UpdateNickname)
			profile.PUT("/birthday", profileHandler.UpdateBirthday)
			profile.PUT("/phone", profileHandler.UpdatePhone)
			profile.PUT("/email", profileHandler.UpdateEmail)
			profile.PUT("/password", profileHandler.ChangePassword)
			profile.POST("/avatar", profileHandler.UploadAvatar)
		}
	}

	return r
}

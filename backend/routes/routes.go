package routes

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/handlers"
	"personal-notes-backend/middleware"
)

// SetupRouter 配置所有路由
func SetupRouter(db *gorm.DB) *gin.Engine {
	r := gin.Default()

	// 创建处理器
	authHandler := handlers.NewAuthHandler(db)
	noteHandler := handlers.NewNoteHandler(db)
	folderHandler := handlers.NewFolderHandler(db)
	profileHandler := handlers.NewProfileHandler(db)

	// 健康检查
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "ok"})
	})

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
		}

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

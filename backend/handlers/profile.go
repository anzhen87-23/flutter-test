package handlers

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/models"
	"personal-notes-backend/utils"
)

// ProfileHandler 个人信息相关处理器
type ProfileHandler struct {
	DB *gorm.DB
}

// NewProfileHandler 创建个人信息处理器
func NewProfileHandler(db *gorm.DB) *ProfileHandler {
	return &ProfileHandler{DB: db}
}

// GetProfile 获取当前用户个人信息
func (h *ProfileHandler) GetProfile(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "用户不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    user.ToResponse(),
	})
}

// UpdateNickname 更新昵称
func (h *ProfileHandler) UpdateNickname(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Nickname string `json:"nickname" binding:"required,max=50"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	h.DB.Model(&models.User{}).Where("id = ?", userID).Update("nickname", req.Nickname)

	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "昵称更新成功"})
}

// UpdateBirthday 更新生日
func (h *ProfileHandler) UpdateBirthday(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		Birthday *time.Time `json:"birthday"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	h.DB.Model(&models.User{}).Where("id = ?", userID).Update("birthday", req.Birthday)

	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "生日更新成功"})
}

// UpdatePhone 更新手机号
func (h *ProfileHandler) UpdatePhone(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		NewPhone string `json:"new_phone" binding:"required"`
		Code     string `json:"code" binding:"required,len=6"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证手机号格式
	if !utils.ValidatePhone(req.NewPhone) {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "手机号格式错误"})
		return
	}

	// 验证密码
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "用户不存在"})
		return
	}
	if !utils.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "密码错误"})
		return
	}

	// 验证验证码
	if !utils.VerifyCode(h.DB, req.NewPhone, req.Code, "verify_phone") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "验证码错误或已过期"})
		return
	}

	// 检查手机号是否被其他用户占用
	var existingUser models.User
	if err := h.DB.Where("phone = ? AND id != ?", req.NewPhone, userID).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"code": 409, "message": "该手机号已被其他用户使用"})
		return
	}

	h.DB.Model(&user).Update("phone", req.NewPhone)

	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "手机号更新成功"})
}

// UpdateEmail 更新邮箱
func (h *ProfileHandler) UpdateEmail(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		NewEmail string `json:"new_email" binding:"required,email"`
		Code     string `json:"code" binding:"required,len=6"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证密码
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "用户不存在"})
		return
	}
	if !utils.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "密码错误"})
		return
	}

	// 验证验证码
	if !utils.VerifyCode(h.DB, req.NewEmail, req.Code, "verify_email") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "验证码错误或已过期"})
		return
	}

	// 检查邮箱是否被其他用户占用
	var existingUser models.User
	if err := h.DB.Where("email = ? AND id != ?", req.NewEmail, userID).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"code": 409, "message": "该邮箱已被其他用户使用"})
		return
	}

	h.DB.Model(&user).Update("email", req.NewEmail)

	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "邮箱更新成功"})
}

// ChangePassword 修改密码（需要旧密码）
func (h *ProfileHandler) ChangePassword(c *gin.Context) {
	userID, _ := c.Get("user_id")

	var req struct {
		OldPassword string `json:"old_password" binding:"required"`
		NewPassword string `json:"new_password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误"})
		return
	}

	// 验证新密码格式
	if err := utils.ValidatePassword(req.NewPassword); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	// 查找用户
	var user models.User
	if err := h.DB.First(&user, userID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "用户不存在"})
		return
	}

	// 验证旧密码
	if !utils.CheckPassword(req.OldPassword, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "旧密码错误"})
		return
	}

	// 检查新旧密码是否相同
	if req.OldPassword == req.NewPassword {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "新密码不能与旧密码相同"})
		return
	}

	// 加密新密码
	hashedPassword, _ := utils.HashPassword(req.NewPassword)
	h.DB.Model(&user).Update("password", hashedPassword)

	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "密码修改成功"})
}

// getUploadDir 获取头像上传目录的绝对路径
func getUploadDir() string {
	// 优先使用环境变量
	if dir := os.Getenv("UPLOAD_DIR"); dir != "" {
		return dir
	}
	// 使用可执行文件所在目录作为基础路径，避免依赖 CWD
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("[avatar] 获取可执行文件路径失败: %v, 回退到 CWD", err)
		return "uploads/avatars"
	}
	return filepath.Join(filepath.Dir(exePath), "uploads", "avatars")
}

// detectMimeByExtension 根据文件扩展名推断 MIME 类型（作为 Content-Type 请求头的回退）
func detectMimeByExtension(filename string) string {
	ext := strings.ToLower(filepath.Ext(filename))
	switch ext {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".png":
		return "image/png"
	case ".gif":
		return "image/gif"
	default:
		return ""
	}
}

// isValidImageMime 判断 MIME 是否为允许的图片类型
func isValidImageMime(mime string) bool {
	return mime == "image/jpeg" || mime == "image/png" || mime == "image/gif"
}

// UploadAvatar 上传头像
func (h *ProfileHandler) UploadAvatar(c *gin.Context) {
	userID, _ := c.Get("user_id")
	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		userIDStr = "0"
	}

	log.Printf("[avatar] 开始上传头像: user_id=%s", userIDStr)

	// 1. 读取 multipart 文件字段
	file, err := c.FormFile("avatar")
	if err != nil {
		log.Printf("[avatar] 读取文件字段失败: user_id=%s, err=%v", userIDStr, err)
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请上传头像文件"})
		return
	}
	log.Printf("[avatar] 收到文件: user_id=%s, filename=%s, size=%d, content_type=%s",
		userIDStr, file.Filename, file.Size, file.Header.Get("Content-Type"))

	// 2. 限制文件大小（5MB）
	if file.Size > 5*1024*1024 {
		log.Printf("[avatar] 文件过大: user_id=%s, size=%d", userIDStr, file.Size)
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "头像大小不能超过5MB"})
		return
	}

	// 3. 检查文件类型：优先用 Content-Type，回退到文件扩展名
	contentType := file.Header.Get("Content-Type")
	if !isValidImageMime(contentType) {
		// 回退：根据文件扩展名推断
		detected := detectMimeByExtension(file.Filename)
		if detected != "" {
			log.Printf("[avatar] Content-Type '%s' 无效, 回退到扩展名推断: %s", contentType, detected)
			contentType = detected
		} else {
			log.Printf("[avatar] 不支持的文件类型: user_id=%s, content_type=%s, filename=%s",
				userIDStr, contentType, file.Filename)
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "仅支持 JPG/PNG/GIF 格式"})
			return
		}
	}

	// 4. 确保上传目录存在（使用绝对路径）
	uploadDir := getUploadDir()
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		log.Printf("[avatar] 创建上传目录失败: dir=%s, err=%v", uploadDir, err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "服务器存储初始化失败"})
		return
	}

	// 5. 生成安全的文件名：用时间戳避免冲突
	ext := strings.ToLower(filepath.Ext(file.Filename))
	safeFilename := fmt.Sprintf("%s_%d%s", userIDStr, time.Now().UnixNano(), ext)
	savePath := filepath.Join(uploadDir, safeFilename)

	if err := c.SaveUploadedFile(file, savePath); err != nil {
		log.Printf("[avatar] 保存文件失败: user_id=%s, path=%s, err=%v", userIDStr, savePath, err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "保存文件失败"})
		return
	}
	log.Printf("[avatar] 文件已保存: user_id=%s, path=%s", userIDStr, savePath)

	// 6. 删除旧头像文件（避免磁盘残留）
	var oldAvatar models.Avatar
	if err := h.DB.Where("user_id = ?", userID).First(&oldAvatar).Error; err == nil {
		if oldAvatar.FilePath != "" {
			if removeErr := os.Remove(oldAvatar.FilePath); removeErr != nil {
				log.Printf("[avatar] 删除旧头像失败: path=%s, err=%v", oldAvatar.FilePath, removeErr)
			} else {
				log.Printf("[avatar] 已删除旧头像: path=%s", oldAvatar.FilePath)
			}
		}
	}

	// 7. 创建或更新头像记录
	var avatar models.Avatar
	h.DB.Where("user_id = ?", userID).First(&avatar)

	avatar.UserID = userID.(uint)
	avatar.FilePath = savePath
	avatar.FileSize = file.Size
	avatar.MimeType = contentType

	if avatar.ID > 0 {
		h.DB.Save(&avatar)
	} else {
		h.DB.Create(&avatar)
	}

	// 8. 更新用户头像 URL（使用 /uploads/avatars/ 路径，对应静态路由）
	avatarURL := "/uploads/avatars/" + safeFilename
	h.DB.Model(&models.User{}).Where("id = ?", userID).Update("avatar_url", avatarURL)

	log.Printf("[avatar] 上传成功: user_id=%s, avatar_url=%s", userIDStr, avatarURL)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "头像上传成功",
		"data": gin.H{
			"avatar_url": avatarURL,
		},
	})
}

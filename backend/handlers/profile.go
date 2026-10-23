package handlers

import (
	"net/http"
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

// UploadAvatar 上传头像
func (h *ProfileHandler) UploadAvatar(c *gin.Context) {
	userID, _ := c.Get("user_id")

	file, err := c.FormFile("avatar")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请上传头像文件"})
		return
	}

	// 限制文件大小（5MB）
	if file.Size > 5*1024*1024 {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "头像大小不能超过5MB"})
		return
	}

	// 检查文件类型
	contentType := file.Header.Get("Content-Type")
	if contentType != "image/jpeg" && contentType != "image/png" && contentType != "image/gif" {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "仅支持 JPG/PNG/GIF 格式"})
		return
	}

	// 保存文件
	userIDStr := c.GetString("user_id")
	if userIDStr == "" {
		userIDStr = "0"
	}
	filename := "avatars/" + userIDStr + "_" + file.Filename
	if err := c.SaveUploadedFile(file, filename); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "保存文件失败"})
		return
	}

	// 创建或更新头像记录
	var avatar models.Avatar
	h.DB.Where("user_id = ?", userID).First(&avatar)

	avatar.UserID = userID.(uint)
	avatar.FilePath = filename
	avatar.FileSize = file.Size
	avatar.MimeType = contentType

	if avatar.ID > 0 {
		h.DB.Save(&avatar)
	} else {
		h.DB.Create(&avatar)
	}

	// 更新用户头像URL
	h.DB.Model(&models.User{}).Where("id = ?", userID).Update("avatar_url", "/"+filename)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "头像上传成功",
		"data": gin.H{
			"avatar_url": "/" + filename,
		},
	})
}

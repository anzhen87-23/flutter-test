package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/models"
	"personal-notes-backend/utils"
)

// AuthHandler 认证相关处理器
type AuthHandler struct {
	DB *gorm.DB
}

// NewAuthHandler 创建认证处理器
func NewAuthHandler(db *gorm.DB) *AuthHandler {
	return &AuthHandler{DB: db}
}

// SendCode 发送验证码（注册/重置密码/验证手机/验证邮箱）
func (h *AuthHandler) SendCode(c *gin.Context) {
	var req struct {
		Target string `json:"target" binding:"required"`
		Type   string `json:"type" binding:"required,oneof=register reset_password verify_phone verify_email"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证目标格式（手机号或邮箱）
	isPhone := utils.ValidatePhone(req.Target)
	isEmail := utils.ValidateEmail(req.Target)

	if !isPhone && !isEmail {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "手机号或邮箱格式错误"})
		return
	}

	// 检查发送频率限制
	if !utils.CheckRateLimit(h.DB, req.Target) {
		c.JSON(http.StatusTooManyRequests, gin.H{"code": 429, "message": "发送过于频繁，请60秒后再试"})
		return
	}

	// 检查每日上限
	if !utils.CheckDailyLimit(h.DB, req.Target) {
		c.JSON(http.StatusTooManyRequests, gin.H{"code": 429, "message": "今日发送次数已达上限"})
		return
	}

	// 生成验证码
	code, err := utils.CreateVerificationCode(h.DB, req.Target, req.Type)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "生成验证码失败"})
		return
	}

	// 发送验证码（开发环境：直接打印）
	fmt.Printf("[验证码] 发送到 %s 的验证码: %s (类型: %s)\n", req.Target, code, req.Type)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "验证码已发送",
		"data":    gin.H{"expires_in": 300},
	})
}

// RegisterByPhone 手机号注册
func (h *AuthHandler) RegisterByPhone(c *gin.Context) {
	var req struct {
		Phone    string `json:"phone" binding:"required"`
		Code     string `json:"code" binding:"required,len=6"`
		Password string `json:"password" binding:"required"`
		Nickname string `json:"nickname"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证手机号格式
	if !utils.ValidatePhone(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "手机号格式错误"})
		return
	}

	// 验证密码格式（6位数字）
	if err := utils.ValidatePassword(req.Password); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	// 验证短信验证码
	if !utils.VerifyCode(h.DB, req.Phone, req.Code, "register") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "验证码错误或已过期"})
		return
	}

	// 检查手机号是否已注册
	var existingUser models.User
	if err := h.DB.Where("phone = ?", req.Phone).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"code": 409, "message": "该手机号已注册"})
		return
	}

	// 加密密码
	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "密码加密失败"})
		return
	}

	// 生成用户名
	username := utils.GenerateUsername(req.Phone)

	// 创建用户
	user := models.User{
		Username: username,
		Phone:    &req.Phone,
		Password: hashedPassword,
		Nickname: req.Nickname,
	}

	if err := h.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "注册失败"})
		return
	}

	// 生成JWT Token
	token, err := utils.GenerateToken(user.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "生成Token失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "注册成功",
		"data": gin.H{
			"user_id": user.ID,
			"token":   token,
			"user":    user.ToResponse(),
		},
	})
}

// RegisterByEmail 邮箱注册
func (h *AuthHandler) RegisterByEmail(c *gin.Context) {
	var req struct {
		Email    string `json:"email" binding:"required,email"`
		Code     string `json:"code" binding:"required,len=6"`
		Password string `json:"password" binding:"required"`
		Nickname string `json:"nickname"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}

	// 验证密码格式
	if err := utils.ValidatePassword(req.Password); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	// 验证邮箱验证码
	if !utils.VerifyCode(h.DB, req.Email, req.Code, "register") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "验证码错误或已过期"})
		return
	}

	// 检查邮箱是否已注册
	var existingUser models.User
	if err := h.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		c.JSON(http.StatusConflict, gin.H{"code": 409, "message": "该邮箱已注册"})
		return
	}

	hashedPassword, err := utils.HashPassword(req.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "密码加密失败"})
		return
	}

	username := utils.GenerateUsername(req.Email)

	user := models.User{
		Username: username,
		Email:    &req.Email,
		Password: hashedPassword,
		Nickname: req.Nickname,
	}

	if err := h.DB.Create(&user).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "注册失败"})
		return
	}

	token, _ := utils.GenerateToken(user.ID)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "注册成功",
		"data": gin.H{
			"user_id": user.ID,
			"token":   token,
			"user":    user.ToResponse(),
		},
	})
}

// Login 登录（支持手机号/邮箱/用户名）
func (h *AuthHandler) Login(c *gin.Context) {
	var req struct {
		Account  string `json:"account" binding:"required"`
		Password string `json:"password" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误"})
		return
	}

	// 验证密码格式
	if err := utils.ValidatePassword(req.Password); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	// 查找用户
	var user models.User
	result := h.DB.Where("phone = ? OR email = ? OR username = ?",
		req.Account, req.Account, req.Account).First(&user)

	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "账号或密码错误"})
		return
	}

	// 验证密码
	if !utils.CheckPassword(req.Password, user.Password) {
		c.JSON(http.StatusUnauthorized, gin.H{"code": 401, "message": "账号或密码错误"})
		return
	}

	token, _ := utils.GenerateToken(user.ID)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "登录成功",
		"data": gin.H{
			"token": token,
			"user":  user.ToResponse(),
		},
	})
}

// ResetPassword 忘记密码重置
func (h *AuthHandler) ResetPassword(c *gin.Context) {
	var req struct {
		Account     string `json:"account" binding:"required"`
		Code        string `json:"code" binding:"required,len=6"`
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

	// 验证验证码
	if !utils.VerifyCode(h.DB, req.Account, req.Code, "reset_password") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "验证码错误或已过期"})
		return
	}

	// 查找用户
	var user models.User
	result := h.DB.Where("phone = ? OR email = ?", req.Account, req.Account).First(&user)
	if result.Error != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "账号不存在"})
		return
	}

	// 加密新密码
	hashedPassword, _ := utils.HashPassword(req.NewPassword)
	h.DB.Model(&user).Update("password", hashedPassword)

	c.JSON(http.StatusOK, gin.H{"code": 200, "message": "密码重置成功"})
}

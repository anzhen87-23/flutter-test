package utils

import (
	"fmt"
	"math/rand"
	"time"

	"gorm.io/gorm"
	"personal-notes-backend/models"
)

// GenerateCode 生成6位数字验证码
func GenerateCode() string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	return fmt.Sprintf("%06d", r.Intn(1000000))
}

// CreateVerificationCode 创建验证码记录
func CreateVerificationCode(db *gorm.DB, target, codeType string) (string, error) {
	code := GenerateCode()
	record := models.VerificationCode{
		Target:    target,
		Code:      code,
		Type:      codeType,
		ExpiresAt: time.Now().Add(5 * time.Minute),
		Used:      false,
	}
	if err := db.Create(&record).Error; err != nil {
		return "", err
	}
	return code, nil
}

// VerifyCode 验证验证码
func VerifyCode(db *gorm.DB, target, code, codeType string) bool {
	var record models.VerificationCode
	err := db.Where(
		"target = ? AND code = ? AND type = ? AND used = ? AND expires_at > ?",
		target, code, codeType, false, time.Now(),
	).First(&record).Error

	if err != nil {
		return false
	}

	// 标记为已使用
	db.Model(&record).Update("used", true)
	return true
}

// CheckRateLimit 检查发送频率限制（60秒内不能重发）
func CheckRateLimit(db *gorm.DB, target string) bool {
	var count int64
	db.Model(&models.VerificationCode{}).
		Where("target = ? AND created_at > ?", target, time.Now().Add(-60*time.Second)).
		Count(&count)
	return count == 0
}

// CheckDailyLimit 检查每日发送上限（10次/天）
func CheckDailyLimit(db *gorm.DB, target string) bool {
	var count int64
	today := time.Now().Format("2006-01-02")
	db.Model(&models.VerificationCode{}).
		Where("target = ? AND DATE(created_at) = ?", target, today).
		Count(&count)
	return count < 10
}

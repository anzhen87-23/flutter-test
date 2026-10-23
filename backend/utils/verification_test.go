package utils

import (
	"testing"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"personal-notes-backend/models"

	"github.com/stretchr/testify/assert"
)

func setupTestDB(t *testing.T) *gorm.DB {
	db, err := gorm.Open(sqlite.Open(":memory:"), &gorm.Config{})
	assert.NoError(t, err)
	err = db.AutoMigrate(&models.VerificationCode{})
	assert.NoError(t, err)
	return db
}

func TestGenerateCode(t *testing.T) {
	code := GenerateCode()
	assert.Len(t, code, 6)
	// 全是数字
	for _, c := range code {
		assert.True(t, c >= '0' && c <= '9')
	}
}

func TestCreateAndVerifyCode(t *testing.T) {
	db := setupTestDB(t)

	code, err := CreateVerificationCode(db, "13800008000", "register")
	assert.NoError(t, err)
	assert.Len(t, code, 6)

	// 正确验证码
	assert.True(t, VerifyCode(db, "13800008000", code, "register"))

	// 已使用过的验证码不能再次验证
	assert.False(t, VerifyCode(db, "13800008000", code, "register"))

	// 错误的验证码
	assert.False(t, VerifyCode(db, "13800008000", "000000", "register"))

	// 错误的目标
	assert.False(t, VerifyCode(db, "13900009000", code, "register"))

	// 错误的类型
	code2, _ := CreateVerificationCode(db, "13800008000", "reset_password")
	assert.False(t, VerifyCode(db, "13800008000", code2, "register"))
}

func TestCheckRateLimit(t *testing.T) {
	db := setupTestDB(t)

	// 第一次发送，应该可以通过
	assert.True(t, CheckRateLimit(db, "13800008000"))

	// 创建一条验证码
	_, err := CreateVerificationCode(db, "13800008000", "register")
	assert.NoError(t, err)

	// 60秒内不能再发
	assert.False(t, CheckRateLimit(db, "13800008000"))

	// 不同目标不受影响
	assert.True(t, CheckRateLimit(db, "13900009000"))
}

func TestCheckDailyLimit(t *testing.T) {
	db := setupTestDB(t)

	// 初始应该可以通过
	assert.True(t, CheckDailyLimit(db, "test@example.com"))

	// 创建10条验证码
	for i := 0; i < 10; i++ {
		code := GenerateCode()
		record := models.VerificationCode{
			Target: "test@example.com",
			Code:   code,
			Type:   "register",
		}
		db.Create(&record)
	}

	// 第10条后，应该达到上限
	assert.False(t, CheckDailyLimit(db, "test@example.com"))
}

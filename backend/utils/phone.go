package utils

import (
	"fmt"
	"math/rand"
	"regexp"
	"strings"
	"time"
)

// 中国大陆手机号：1[3-9]开头的11位数字
var phoneRegex = regexp.MustCompile(`^1[3-9]\d{9}$`)

// 邮箱格式验证
var emailRegex = regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)

// ValidatePhone 验证中国大陆手机号格式
func ValidatePhone(phone string) bool {
	return phoneRegex.MatchString(phone)
}

// ValidateEmail 验证邮箱格式
func ValidateEmail(email string) bool {
	return emailRegex.MatchString(email) && strings.Contains(email, "@")
}

// MaskPhone 手机号脱敏显示（138****8000）
func MaskPhone(phone string) string {
	if len(phone) != 11 {
		return phone
	}
	return phone[:3] + "****" + phone[7:]
}

// GenerateUsername 根据手机号/邮箱生成用户名
func GenerateUsername(account string) string {
	r := rand.New(rand.NewSource(time.Now().UnixNano()))
	suffix := fmt.Sprintf("%04d", r.Intn(10000))

	if ValidatePhone(account) {
		// 手机号：使用后4位+随机数
		return "u_" + account[7:] + suffix
	}
	// 邮箱：使用@前缀+随机数
	atIdx := -1
	for i, c := range account {
		if c == '@' {
			atIdx = i
			break
		}
	}
	if atIdx < 0 {
		return "u_" + account + suffix
	}
	prefix := account[:atIdx]
	if len(prefix) > 8 {
		return "u_" + prefix[:8] + suffix
	}
	return "u_" + prefix + suffix
}

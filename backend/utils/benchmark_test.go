package utils

import (
	"testing"
)

// BenchmarkValidatePassword 密码验证性能
func BenchmarkValidatePassword(b *testing.B) {
	for i := 0; i < b.N; i++ {
		ValidatePassword("123456")
	}
}

// BenchmarkHashPassword 密码哈希性能（bcrypt是故意慢的）
func BenchmarkHashPassword(b *testing.B) {
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		HashPassword("123456")
	}
}

// BenchmarkCheckPassword 密码校验性能
func BenchmarkCheckPassword(b *testing.B) {
	hash, _ := HashPassword("123456")
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		CheckPassword("123456", hash)
	}
}

// BenchmarkGenerateToken JWT生成性能
func BenchmarkGenerateToken(b *testing.B) {
	for i := 0; i < b.N; i++ {
		GenerateToken(1)
	}
}

// BenchmarkParseToken JWT解析性能
func BenchmarkParseToken(b *testing.B) {
	token, _ := GenerateToken(1)
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		ParseToken(token)
	}
}

// BenchmarkValidatePhone 手机号验证性能
func BenchmarkValidatePhone(b *testing.B) {
	for i := 0; i < b.N; i++ {
		ValidatePhone("13800008000")
	}
}

// BenchmarkMaskPhone 手机号脱敏性能
func BenchmarkMaskPhone(b *testing.B) {
	for i := 0; i < b.N; i++ {
		MaskPhone("13800008000")
	}
}

// BenchmarkGenerateCode 验证码生成性能
func BenchmarkGenerateCode(b *testing.B) {
	for i := 0; i < b.N; i++ {
		GenerateCode()
	}
}

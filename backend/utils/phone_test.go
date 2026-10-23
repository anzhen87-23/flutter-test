package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestValidatePhone(t *testing.T) {
	assert.True(t, ValidatePhone("13800008000"))
	assert.True(t, ValidatePhone("13912345678"))
	assert.True(t, ValidatePhone("15800000000"))
	assert.True(t, ValidatePhone("18612345678"))

	// 无效手机号
	assert.False(t, ValidatePhone(""))
	assert.False(t, ValidatePhone("12345678901"))  // 不是1开头
	assert.False(t, ValidatePhone("1380000800"))   // 10位
	assert.False(t, ValidatePhone("138000080001")) // 12位
	assert.False(t, ValidatePhone("12800008000"))  // 第二位不是3-9
	assert.False(t, ValidatePhone("abcdefghijk"))  // 字母
}

func TestMaskPhone(t *testing.T) {
	assert.Equal(t, "138****8000", MaskPhone("13800008000"))
	assert.Equal(t, "139****5678", MaskPhone("13912345678"))
	// 非标准长度直接返回
	assert.Equal(t, "1234", MaskPhone("1234"))
}

func TestGenerateUsername_Phone(t *testing.T) {
	username := GenerateUsername("13800008000")
	assert.Contains(t, username, "u_")
	assert.True(t, len(username) > 3)
}

func TestGenerateUsername_Email(t *testing.T) {
	username := GenerateUsername("test@example.com")
	assert.Contains(t, username, "u_")
	assert.Contains(t, username, "test")
}

func TestGenerateUsername_LongEmail(t *testing.T) {
	username := GenerateUsername("verylongemailname@example.com")
	assert.Contains(t, username, "u_")
}

func TestGenerateUsername_NoAt(t *testing.T) {
	username := GenerateUsername("noemailatall")
	assert.Contains(t, username, "u_")
}

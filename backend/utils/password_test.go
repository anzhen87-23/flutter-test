package utils

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestValidatePassword_Valid(t *testing.T) {
	assert.NoError(t, ValidatePassword("123456"))
	assert.NoError(t, ValidatePassword("000000"))
	assert.NoError(t, ValidatePassword("999999"))
}

func TestValidatePassword_Invalid(t *testing.T) {
	assert.Error(t, ValidatePassword("12345"))   // 5位
	assert.Error(t, ValidatePassword("1234567"))  // 7位
	assert.Error(t, ValidatePassword("abcdef"))   // 字母
	assert.Error(t, ValidatePassword("12345a"))   // 包含字母
	assert.Error(t, ValidatePassword(""))         // 空
	assert.Error(t, ValidatePassword("12 345"))   // 包含空格
}

func TestHashPassword_And_CheckPassword(t *testing.T) {
	password := "123456"
	hash, err := HashPassword(password)
	assert.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)

	assert.True(t, CheckPassword(password, hash))
	assert.False(t, CheckPassword("654321", hash))
	assert.False(t, CheckPassword("", hash))
}

func TestHashPassword_InvalidPassword(t *testing.T) {
	_, err := HashPassword("abc")
	assert.Error(t, err)

	_, err = HashPassword("")
	assert.Error(t, err)
}

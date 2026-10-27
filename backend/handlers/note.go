package handlers

import (
	"bytes"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
	"personal-notes-backend/models"
)

// NoteHandler 笔记相关处理器
type NoteHandler struct {
	DB *gorm.DB
}

// NewNoteHandler 创建笔记处理器
func NewNoteHandler(db *gorm.DB) *NoteHandler {
	return &NoteHandler{DB: db}
}

// ListNotes 获取笔记列表（支持分页和按文件夹筛选）
func (h *NoteHandler) ListNotes(c *gin.Context) {
	userID, _ := c.Get("user_id")
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	folderIDStr := c.Query("folder_id")

	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	query := h.DB.Where("user_id = ?", userID)
	if folderIDStr != "" {
		folderID, err := strconv.ParseUint(folderIDStr, 10, 64)
		if err == nil {
			query = query.Where("folder_id = ?", folderID)
		}
	}

	var total int64
	query.Model(&models.Note{}).Count(&total)

	var notes []models.Note
	if err := query.Order("updated_at DESC").Offset(offset).Limit(pageSize).Find(&notes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询笔记失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data": gin.H{
			"notes":     notes,
			"total":     total,
			"page":      page,
			"page_size": pageSize,
		},
	})
}

// GetNote 获取单个笔记详情
func (h *NoteHandler) GetNote(c *gin.Context) {
	userID, _ := c.Get("user_id")
	noteID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的笔记ID"})
		return
	}

	var note models.Note
	if err := h.DB.Where("id = ? AND user_id = ?", noteID, userID).First(&note).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "笔记不存在"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "查询成功",
		"data":    note,
	})
}

// CreateNote 创建笔记
func (h *NoteHandler) CreateNote(c *gin.Context) {
	userID, _ := c.Get("user_id")

	// 打印原始请求体用于调试
	bodyBytes, _ := io.ReadAll(c.Request.Body)
	log.Printf("[note] CreateNote 原始请求体: %s", string(bodyBytes))
	c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

	var req struct {
		Title    string `json:"title" binding:"required,max=200"`
		Content  string `json:"content"`
		FolderID *uint  `json:"folder_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[note] CreateNote 解析错误: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}
	log.Printf("[note] CreateNote 解析结果: title=%s, folder_id=%v", req.Title, req.FolderID)

	// 如果指定了文件夹，验证文件夹是否存在且属于当前用户
	if req.FolderID != nil {
		var folder models.Folder
		if err := h.DB.Where("id = ? AND user_id = ?", *req.FolderID, userID).First(&folder).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "指定的文件夹不存在"})
			return
		}
	}

	note := models.Note{
		UserID:   userID.(uint),
		Title:    req.Title,
		Content:  req.Content,
		FolderID: req.FolderID,
	}

	if err := h.DB.Create(&note).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "创建笔记失败"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"code":    201,
		"message": "创建成功",
		"data":    note,
	})
}

// UpdateNote 更新笔记
func (h *NoteHandler) UpdateNote(c *gin.Context) {
	userID, _ := c.Get("user_id")
	noteID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的笔记ID"})
		return
	}

	// 打印原始请求体用于调试
	bodyBytes, _ := io.ReadAll(c.Request.Body)
	log.Printf("[note] UpdateNote 原始请求体: %s", string(bodyBytes))
	c.Request.Body = io.NopCloser(bytes.NewBuffer(bodyBytes))

	var req struct {
		Title    string `json:"title" binding:"omitempty,max=200"`
		Content  *string `json:"content"`
		FolderID *uint  `json:"folder_id"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[note] UpdateNote 解析错误: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请求参数错误: " + err.Error()})
		return
	}
	log.Printf("[note] UpdateNote 解析结果: title=%s, folder_id=%v", req.Title, req.FolderID)

	// 验证笔记存在且属于当前用户
	var note models.Note
	if err := h.DB.Where("id = ? AND user_id = ?", noteID, userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "笔记不存在"})
		return
	}

	// 如果指定了文件夹，验证文件夹存在
	if req.FolderID != nil {
		var folder models.Folder
		if err := h.DB.Where("id = ? AND user_id = ?", *req.FolderID, userID).First(&folder).Error; err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "指定的文件夹不存在"})
			return
		}
	}

	updates := map[string]interface{}{}
	if req.Title != "" {
		updates["title"] = req.Title
	}
	if req.Content != nil {
		updates["content"] = *req.Content
	}
	if req.FolderID != nil {
		updates["folder_id"] = *req.FolderID
	}

	if len(updates) > 0 {
		h.DB.Model(&note).Updates(updates)
	}

	// 重新查询获取更新后的数据
	h.DB.Where("id = ?", noteID).First(&note)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "更新成功",
		"data":    note,
	})
}

// DeleteNote 删除笔记
func (h *NoteHandler) DeleteNote(c *gin.Context) {
	userID, _ := c.Get("user_id")
	noteID, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的笔记ID"})
		return
	}

	var note models.Note
	if err := h.DB.Where("id = ? AND user_id = ?", noteID, userID).First(&note).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "笔记不存在"})
		return
	}

	// 删除笔记关联的图片文件
	if note.Content != "" {
		deleteNoteImages(note.Content)
	}

	if err := h.DB.Delete(&note).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "删除成功",
		"data":    nil,
	})
}

// UploadNoteImage 上传笔记图片或视频
func (h *NoteHandler) UploadNoteImage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	userIDStr := c.GetString("user_id")

	log.Printf("[note-media] 开始上传文件: user_id=%s", userIDStr)
	_ = userID // 用于后续可能的权限校验

	// 读取 multipart 文件
	file, err := c.FormFile("image")
	if err != nil {
		// 兼容视频字段名
		file, err = c.FormFile("video")
		if err != nil {
			log.Printf("[note-media] 读取文件字段失败: err=%v", err)
			c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "请上传文件"})
			return
		}
	}

	// 检查文件类型
	contentType := file.Header.Get("Content-Type")
	ext := strings.ToLower(filepath.Ext(file.Filename))

	validImageTypes := map[string]bool{
		"image/jpeg": true, "image/png": true, "image/gif": true, "image/webp": true,
	}
	validImageExtensions := map[string]bool{
		".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true,
	}
	validVideoTypes := map[string]bool{
		"video/mp4": true, "video/quicktime": true, "video/webm": true, "video/x-msvideo": true,
	}
	validVideoExtensions := map[string]bool{
		".mp4": true, ".mov": true, ".webm": true, ".avi": true,
	}

	isImage := validImageTypes[contentType] || validImageExtensions[ext]
	isVideo := validVideoTypes[contentType] || validVideoExtensions[ext]

	if !isImage && !isVideo {
		log.Printf("[note-media] 不支持的文件类型: content_type=%s, ext=%s", contentType, ext)
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "仅支持图片(JPG/PNG/GIF/WEBP)或视频(MP4/MOV/WEBM/AVI)格式"})
		return
	}

	// 文件大小限制：图片 10MB，视频 50MB
	var maxSize int64
	var fileType string
	if isVideo {
		maxSize = 50 * 1024 * 1024
		fileType = "视频"
	} else {
		maxSize = 10 * 1024 * 1024
		fileType = "图片"
	}

	if file.Size > maxSize {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": fmt.Sprintf("%s大小不能超过%dMB", fileType, maxSize/1024/1024)})
		return
	}

	// 确保上传目录存在
	uploadDir := getNoteUploadDir()
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		log.Printf("[note-media] 创建目录失败: err=%v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "服务器存储初始化失败"})
		return
	}

	// 生成安全的文件名
	safeFilename := fmt.Sprintf("%s_%d%s", userIDStr, time.Now().UnixNano(), ext)
	savePath := filepath.Join(uploadDir, safeFilename)

	if err := c.SaveUploadedFile(file, savePath); err != nil {
		log.Printf("[note-media] 保存文件失败: err=%v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "保存文件失败"})
		return
	}

	fileURL := "/uploads/notes/" + safeFilename
	log.Printf("[note-media] 上传成功: type=%s, url=%s", fileType, fileURL)

	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "上传成功",
		"data": gin.H{
			"url":       fileURL,
			"filename":  safeFilename,
			"size":      file.Size,
			"file_type": fileType,
		},
	})
}

// DeleteNoteImage 删除笔记图片
func (h *NoteHandler) DeleteNoteImage(c *gin.Context) {
	userID, _ := c.Get("user_id")
	filename := c.Param("filename")

	// 防止路径遍历
	if strings.Contains(filename, "..") || strings.Contains(filename, "/") || strings.Contains(filename, "\\") {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "无效的文件名"})
		return
	}

	filePath := filepath.Join(getNoteUploadDir(), filename)

	// 验证文件存在
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		c.JSON(http.StatusNotFound, gin.H{"code": 404, "message": "图片不存在"})
		return
	}

	if err := os.Remove(filePath); err != nil {
		log.Printf("[note-image] 删除文件失败: user_id=%v, file=%s, err=%v", userID, filename, err)
		c.JSON(http.StatusInternalServerError, gin.H{"code": 500, "message": "删除失败"})
		return
	}

	log.Printf("[note-image] 删除成功: user_id=%v, file=%s", userID, filename)
	c.JSON(http.StatusOK, gin.H{
		"code":    200,
		"message": "删除成功",
	})
}

// getNoteUploadDir 获取笔记图片上传目录
func getNoteUploadDir() string {
	if dir := os.Getenv("NOTES_UPLOAD_DIR"); dir != "" {
		return dir
	}
	exePath, err := os.Executable()
	if err != nil {
		log.Printf("[note-image] 获取可执行文件路径失败: %v, 回退到 CWD", err)
		return "uploads/notes"
	}
	return filepath.Join(filepath.Dir(exePath), "uploads", "notes")
}

// deleteNoteImages 从 HTML 内容中提取并删除所有笔记图片
func deleteNoteImages(content string) {
	// 简单提取 /uploads/notes/ 开头的图片路径
	prefix := "/uploads/notes/"
	uploadDir := getNoteUploadDir()

	remaining := content
	for {
		idx := strings.Index(remaining, prefix)
		if idx == -1 {
			break
		}
		remaining = remaining[idx+len(prefix):]

		// 提取文件名（到引号、空格、括号或结尾）
		end := len(remaining)
		for i, ch := range remaining {
			if ch == '"' || ch == '\'' || ch == ' ' || ch == ')' || ch == '>' || ch == '&' {
				end = i
				break
			}
		}
		filename := remaining[:end]

		// 删除文件
		filePath := filepath.Join(uploadDir, filename)
		if err := os.Remove(filePath); err != nil {
			log.Printf("[note-image] 清理图片失败: %s, err=%v", filePath, err)
		} else {
			log.Printf("[note-image] 已清理图片: %s", filePath)
		}

		remaining = remaining[end:]
	}
}

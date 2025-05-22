FileEncoding, UTF-8
HttpPost(url, token, sendData, callback) {
    ToolTip, AI请求中
    try {
        whr := ComObjCreate("WinHttp.wsRequest.5.1")
        ; 设置超时时间(毫秒): 解析域名超时, 连接超时, 发送超时, 接收超时
        whr.SetTimeouts(30000, 30000, 30000, 1200000)
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Authorization", "Bearer " token)
        whr.SetRequestHeader("Content-Type", "application/json")
        
        ; 创建 ADOStream 对象用于读取响应
        adoStream := ComObjCreate("ADODB.Stream")
        adoStream.Type := 1  ; 二进制
        adoStream.Mode := 3  ; 读写模式
        adoStream.Open()
        
        ; 设置响应体处理
        whr.Option(6) := false  ; 禁用自动重定向
        whr.Send(sendData)
        
        ; 等待响应开始
        while whr.ReadyState != 4 {
            Sleep 10
        }
        
        if (whr.Status != 200) {
            throw Exception("API请求失败，状态码：" whr.Status "`n响应：" whr.ResponseText)
        }
        
        ; 获取响应流
        responseStream := whr.ResponseStream
        buffer := ComObjArray(0x11, 8192)  ; VT_UI1 类型的数组，大小为 8KB
        
        ; 循环读取响应数据
        while true {
            bytesRead := responseStream.Read(buffer, 8192)
            if (bytesRead = 0) {
                break
            }
            
            ; 将二进制数据写入 ADOStream
            adoStream.SetEOS()
            adoStream.Write(buffer)
            adoStream.Position := 0
            
            ; 转换为文本并调用回调函数
            text := byteToStr(adoStream.Read(), "utf-8")
            callback.Call(text)
            
            ; 清空流以准备下一次读取
            adoStream.Position := 0
            adoStream.SetEOS()
        }
        
        ; 清理资源
        adoStream.Close()
        ToolTip
        return true
    } catch e {
        ToolTip
        MsgBox, 16, 错误, API请求失败, 请检查api设置：`n%e%
        return false
    }
}

SendAsyncPost(url, token, postData) {
    try {
        ; 创建 ws 对象
        ws := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        
        ; 设置为异步模式
        ws.Option(6) := False  ; 禁用重定向
        
        ; 打开连接 (True 表示异步)
        ws.Open("POST", url, True)
        
        ; 设置请求头
        ws.SetRequestHeader("Content-Type", "application/json")
        ws.SetRequestHeader("Authorization", "Bearer " token)
        ; 发送请求
        ws.Send(postData)
        
        ; 等待请求完成
        while ws.ReadyState != 4
        {
            if (ws.ReadyState >= 3)
            {
                try {
                    partialResponse := ws.ResponseText
                    if (partialResponse)
                        print("`n部分响应内容：`n" . partialResponse)

                }
            }
        }
        
        ; 获取响应
        if (ws.Status = 200) {
            response := ws.ResponseText
            MsgBox % "请求成功！`n响应内容：" response
        } else {
            MsgBox % "请求失败！`n状态码：" ws.Status "`n错误信息：" ws.StatusText
        }
    }
    catch e {
        MsgBox % "发生错误：" e.message
    }
}
SendPostRequest(url, token, postData) {
    ; 创建 WinHTTP 对象
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    

    ; 配置请求
    whr.Open("POST", url, false)  ; 使用同步请求
    whr.SetRequestHeader("Content-Type", "application/json")
    whr.SetRequestHeader("Authorization", "Bearer " token)
    
    ; 设置超时（毫秒）
    whr.SetTimeouts(0, 5000, 5000, 5000)
    
    try {
        ; 发送请求
        whr.Send(postData)
        
        ; 检查响应状态
        if (whr.Status = 200) {
            ; 获取响应流
            stream := whr.ResponseStream
            adoStream := ComObjCreate("ADODB.Stream")
            
            ; 设置流属性
            adoStream.Type := 1  ; 二进制
            adoStream.Mode := 3  ; 读写模式
            adoStream.Open()
            
            ; 缓冲区大小（字节）
            bufferSize := 1024
            
            ; 读取数据
            while (!stream.EOS) {
                ; 创建缓冲区
                buffer := ComObjCreate("VT_ARRAY | VT_UI1", bufferSize)
                
                ; 读取数据到缓冲区
                bytesRead := stream.Read(buffer, bufferSize)
                
                if (bytesRead > 0) {
                    ; 写入数据到ADO流
                    adoStream.Write(buffer)
                    
                    ; 转换为文本并处理
                    adoStream.Position := 0
                    adoStream.Type := 2  ; 文本
                    text := adoStream.ReadText()
                    
                    ; 处理接收到的数据
                    ProcessStreamData(text)
                    
                    ; 清理流
                    adoStream.Close()
                    adoStream.Open()
                    adoStream.Type := 1
                }
                
                ; 添加小延迟避免CPU占用过高
                Sleep 10
            }
            
            ; 清理资源
            adoStream.Close()
            MsgBox "响应接收完成"
        }
        else {
            MsgBox % "请求失败，状态码: " whr.Status
        }
    }
    catch e {
        MsgBox % "发生错误: " e.message
    }
}

; 处理流式数据的函数
ProcessStreamData(data) {
    ; 这里处理接收到的数据片段
    ; 可以根据需要解析JSON或其他格式
    MsgBox % "收到数据: " data
}


byteToStr(body, charset){
    Stream := ComObjCreate("Adodb.Stream")
    Stream.Type := 1
    Stream.Mode := 3
    Stream.Open()
    Stream.Write(body)
    Stream.Position := 0
    Stream.Type := 2
    Stream.Charset := charset
    str := Stream.ReadText()
    Stream.Close()
    return str
}
;----------------------------- 
; 示例回调函数：处理每个数据块
;-----------------------------
OnStreamData(data) {
    ; 在这里处理每个接收到的数据块
    ; 例如，将其显示在工具提示中或追加到全局变量
    MsgBox, % "接收到数据块:`n" data
    ; 或者将数据追加到全局变量
    global fullResponse
    fullResponse .= data
}

;----------------------------- 
; 使用示例
;-----------------------------
sendData := "
(
{
""model"": ""deepseek-chat"",
""messages"": [
{
""role"": ""user"",
""content"": ""4482个小时是多少天？""
}
],
""stream"": true
}
)"


fullResponse := ""

; 发送 POST 请求并开始流式处理响应
; HttpPost("http://127.0.0.1:1000/v1/chat/completions", "sk-WvMkGkPdrUIXTwRk3014F2C586D74c1a99350165Ec847a69", sendData, Func("OnStreamData"))
; SendAsyncPost("http://127.0.0.1:1000/v1/chat/completions", "sk-WvMkGkPdrUIXTwRk3014F2C586D74c1a99350165Ec847a69", sendData)

SendPostRequest("http://127.0.0.1:1000/v1/chat/completions", "sk-WvMkGkPdrUIXTwRk3014F2C586D74c1a99350165Ec847a69", sendData)


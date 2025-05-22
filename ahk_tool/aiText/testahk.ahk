FileEncoding, UTF-8
HttpPost(url, token, sendData, callback) {
    ToolTip, AI������
    try {
        whr := ComObjCreate("WinHttp.wsRequest.5.1")
        ; ���ó�ʱʱ��(����): ����������ʱ, ���ӳ�ʱ, ���ͳ�ʱ, ���ճ�ʱ
        whr.SetTimeouts(30000, 30000, 30000, 1200000)
        whr.Open("POST", url, true)
        whr.SetRequestHeader("Authorization", "Bearer " token)
        whr.SetRequestHeader("Content-Type", "application/json")
        
        ; ���� ADOStream �������ڶ�ȡ��Ӧ
        adoStream := ComObjCreate("ADODB.Stream")
        adoStream.Type := 1  ; ������
        adoStream.Mode := 3  ; ��дģʽ
        adoStream.Open()
        
        ; ������Ӧ�崦��
        whr.Option(6) := false  ; �����Զ��ض���
        whr.Send(sendData)
        
        ; �ȴ���Ӧ��ʼ
        while whr.ReadyState != 4 {
            Sleep 10
        }
        
        if (whr.Status != 200) {
            throw Exception("API����ʧ�ܣ�״̬�룺" whr.Status "`n��Ӧ��" whr.ResponseText)
        }
        
        ; ��ȡ��Ӧ��
        responseStream := whr.ResponseStream
        buffer := ComObjArray(0x11, 8192)  ; VT_UI1 ���͵����飬��СΪ 8KB
        
        ; ѭ����ȡ��Ӧ����
        while true {
            bytesRead := responseStream.Read(buffer, 8192)
            if (bytesRead = 0) {
                break
            }
            
            ; ������������д�� ADOStream
            adoStream.SetEOS()
            adoStream.Write(buffer)
            adoStream.Position := 0
            
            ; ת��Ϊ�ı������ûص�����
            text := byteToStr(adoStream.Read(), "utf-8")
            callback.Call(text)
            
            ; �������׼����һ�ζ�ȡ
            adoStream.Position := 0
            adoStream.SetEOS()
        }
        
        ; ������Դ
        adoStream.Close()
        ToolTip
        return true
    } catch e {
        ToolTip
        MsgBox, 16, ����, API����ʧ��, ����api���ã�`n%e%
        return false
    }
}

SendAsyncPost(url, token, postData) {
    try {
        ; ���� ws ����
        ws := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        
        ; ����Ϊ�첽ģʽ
        ws.Option(6) := False  ; �����ض���
        
        ; ������ (True ��ʾ�첽)
        ws.Open("POST", url, True)
        
        ; ��������ͷ
        ws.SetRequestHeader("Content-Type", "application/json")
        ws.SetRequestHeader("Authorization", "Bearer " token)
        ; ��������
        ws.Send(postData)
        
        ; �ȴ��������
        while ws.ReadyState != 4
        {
            if (ws.ReadyState >= 3)
            {
                try {
                    partialResponse := ws.ResponseText
                    if (partialResponse)
                        print("`n������Ӧ���ݣ�`n" . partialResponse)

                }
            }
        }
        
        ; ��ȡ��Ӧ
        if (ws.Status = 200) {
            response := ws.ResponseText
            MsgBox % "����ɹ���`n��Ӧ���ݣ�" response
        } else {
            MsgBox % "����ʧ�ܣ�`n״̬�룺" ws.Status "`n������Ϣ��" ws.StatusText
        }
    }
    catch e {
        MsgBox % "��������" e.message
    }
}
SendPostRequest(url, token, postData) {
    ; ���� WinHTTP ����
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    

    ; ��������
    whr.Open("POST", url, false)  ; ʹ��ͬ������
    whr.SetRequestHeader("Content-Type", "application/json")
    whr.SetRequestHeader("Authorization", "Bearer " token)
    
    ; ���ó�ʱ�����룩
    whr.SetTimeouts(0, 5000, 5000, 5000)
    
    try {
        ; ��������
        whr.Send(postData)
        
        ; �����Ӧ״̬
        if (whr.Status = 200) {
            ; ��ȡ��Ӧ��
            stream := whr.ResponseStream
            adoStream := ComObjCreate("ADODB.Stream")
            
            ; ����������
            adoStream.Type := 1  ; ������
            adoStream.Mode := 3  ; ��дģʽ
            adoStream.Open()
            
            ; ��������С���ֽڣ�
            bufferSize := 1024
            
            ; ��ȡ����
            while (!stream.EOS) {
                ; ����������
                buffer := ComObjCreate("VT_ARRAY | VT_UI1", bufferSize)
                
                ; ��ȡ���ݵ�������
                bytesRead := stream.Read(buffer, bufferSize)
                
                if (bytesRead > 0) {
                    ; д�����ݵ�ADO��
                    adoStream.Write(buffer)
                    
                    ; ת��Ϊ�ı�������
                    adoStream.Position := 0
                    adoStream.Type := 2  ; �ı�
                    text := adoStream.ReadText()
                    
                    ; ������յ�������
                    ProcessStreamData(text)
                    
                    ; ������
                    adoStream.Close()
                    adoStream.Open()
                    adoStream.Type := 1
                }
                
                ; ���С�ӳٱ���CPUռ�ù���
                Sleep 10
            }
            
            ; ������Դ
            adoStream.Close()
            MsgBox "��Ӧ�������"
        }
        else {
            MsgBox % "����ʧ�ܣ�״̬��: " whr.Status
        }
    }
    catch e {
        MsgBox % "��������: " e.message
    }
}

; ������ʽ���ݵĺ���
ProcessStreamData(data) {
    ; ���ﴦ����յ�������Ƭ��
    ; ���Ը�����Ҫ����JSON��������ʽ
    MsgBox % "�յ�����: " data
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
; ʾ���ص�����������ÿ�����ݿ�
;-----------------------------
OnStreamData(data) {
    ; �����ﴦ��ÿ�����յ������ݿ�
    ; ���磬������ʾ�ڹ�����ʾ�л�׷�ӵ�ȫ�ֱ���
    MsgBox, % "���յ����ݿ�:`n" data
    ; ���߽�����׷�ӵ�ȫ�ֱ���
    global fullResponse
    fullResponse .= data
}

;----------------------------- 
; ʹ��ʾ��
;-----------------------------
sendData := "
(
{
""model"": ""deepseek-chat"",
""messages"": [
{
""role"": ""user"",
""content"": ""4482��Сʱ�Ƕ����죿""
}
],
""stream"": true
}
)"


fullResponse := ""

; ���� POST ���󲢿�ʼ��ʽ������Ӧ
; HttpPost("http://127.0.0.1:1000/v1/chat/completions", "sk-WvMkGkPdrUIXTwRk3014F2C586D74c1a99350165Ec847a69", sendData, Func("OnStreamData"))
; SendAsyncPost("http://127.0.0.1:1000/v1/chat/completions", "sk-WvMkGkPdrUIXTwRk3014F2C586D74c1a99350165Ec847a69", sendData)

SendPostRequest("http://127.0.0.1:1000/v1/chat/completions", "sk-WvMkGkPdrUIXTwRk3014F2C586D74c1a99350165Ec847a69", sendData)


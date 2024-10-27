from zhipuai import ZhipuAI
import base64
import asyncio

client = ZhipuAI(api_key="d0e251073f6180cffc3382b462018dfa.c6efQ3REhPjeM3HC") # 填写您自己的APIKey

async def process_image(request):
    response = client.chat.completions.create(
        model="glm-4v-plus",
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "type": "image_url",
                        "image_url": {
                            "url": request.image_base64
                        }
                    },
                    {
                        "type": "text",
                        "text": """图片是一个ppt讲解的现场照片。请按以下格式结构化地给出PPT中的文字内容：

                        1. 使用Markdown格式
                        2. 以'# 标题：'开始，给出PPT的主标题
                        3. 接下来使用'## 正文：'，然后列出PPT中的主要内容
                        4. 在正文中，使用适当的Markdown标记（如###, -, 1. 等）来表示不同层级的内容
                        5. 如有表格，请使用Markdown表格语法
                        6. 不要描述演讲的现场情况，只摘取PPT中的实际内容
                        7. 保持原PPT的结构和层次
                        8. 确保所有输出内容均为中文。如果提取的内容为英文，请将其翻译成中文

                        请按照上述格式输出PPT的内容。"""
                    }
                ]
            }
        ],
        stream=True
    )
    for chunk in response:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content

if __name__ == "__main__":
    # 测试函数
    async def test_process_image():
        img_path = "/home/admin/photoPPT/WechatIMG19501.jpeg"
        with open(img_path, 'rb') as img_file:
            img_base = base64.b64encode(img_file.read()).decode('utf-8')
        
        class MockRequest:
            def __init__(self, image_base64):
                self.image_base64 = image_base64
        
        mock_request = MockRequest(img_base)
        async for content in process_image(mock_request):
            print(content, end='', flush=True)

    asyncio.run(test_process_image())

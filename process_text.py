import asyncio
from openai import OpenAI
from dotenv import load_dotenv
import os

load_dotenv()

async def process_text(request):
    prompt = '''以下是几段顺序描述文本，请你结合文本内容，以演讲者的视角串联起来形成一段短文来总结这部分内容，精简文字表达。
    要求串联起相同或相近的关键词，体现文本段落之间的对比与顺承等关系的逻辑，不需要表述无关信息例如场景与展示形式。'''
    prompt_final = request.all_text + prompt
    client = OpenAI(
        # This is the default and can be omitted
        api_key="sk-daavnvd3e4ky7znl",
        base_url="https://cloud.infini-ai.com/maas/qwen2-72b-instruct/nvidia/"
    )

    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": prompt_final,
            }
        ],
        model="qwen2-72b-instruct",
        stream=True,
    )
    for chunk in chat_completion:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content

async def process_keyword(request):
    prompt = '''以下是几段顺序描述的文本，请你结合文本内容，根据关键词与标题整理成为一个思维导图式的结构。主要分为两个层级，严格遵循具体格式例如：
    一、xxx
    1.1、xxx
    1.2、xxx
    二、xxx
    2.1、xxx
    2.2、xxx
    其中每条的内容控制在十个字以内，行与行之间不要空行，不需要表述无关信息例如标题与关键词是什么，不要做其他的介绍和解释。'''
    prompt_final = request.all_text + prompt
    client = OpenAI(
        # This is the default and can be omitted
        api_key="sk-daavnvd3e4ky7znl",
        base_url="https://cloud.infini-ai.com/maas/qwen2-72b-instruct/nvidia/"
    )

    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": prompt_final,
            }
        ],
        model="qwen2-72b-instruct"
    )
    return chat_completion.choices[0].message.content

async def process_text_meaning(request):
    prompt = '''简要地解释以下词语：'''
    prompt_final = prompt + request.text
    client = OpenAI(
        # This is the default and can be omitted
        api_key="sk-daavnvd3e4ky7znl",
        base_url="https://cloud.infini-ai.com/maas/qwen2-72b-instruct/nvidia/"
    )

    chat_completion = client.chat.completions.create(
        messages=[
            {
                "role": "user",
                "content": prompt_final,
            }
        ],
        model="qwen2-72b-instruct",
        stream=True,
    )
    for chunk in chat_completion:
        if chunk.choices[0].delta.content is not None:
            yield chunk.choices[0].delta.content

if __name__ == "__main__":
    # 测试函数
    async def test_process_text_and_keyword():
        class MockRequest:
            def __init__(self, all_text):
                self.all_text = all_text

        test_text = """
        # 标题：人工智能的发展与应用

        ## 正文：
        ### 1. 人工智能的定义
        - 模拟人类智能的计算机系统
        - 能够学习、推理和自主决策

        ### 2. 人工智能的主要应用领域
        1. 医疗诊断
        2. 自动驾驶
        3. 自然语言处理
        4. 金融分析

        ### 3. 人工智能的未来发展趋势
        - 更强大的机器学习算法
        - 与物联网的深度融合
        - 伦理和隐私问题的解决
        """

        mock_request = MockRequest(test_text)

        print("测试 process_text 函数:")
        async for content in process_text(mock_request):
            print(content, end='', flush=True)
        print("\n\n测试 process_keyword 函数:")
        result = await process_keyword(mock_request)
        print(result)

    asyncio.run(test_process_text_and_keyword())

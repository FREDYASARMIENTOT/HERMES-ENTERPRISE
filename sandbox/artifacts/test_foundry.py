from openai import OpenAI

client = OpenAI(
    api_key="AH1jBlWnsrspX3w9MZA587AWqVRwKFqiZi6PwPZNQ1ZMFIaj57tBJQQJ99CGACHYHv6XJ3w3AAAAACOGrEl0",
    base_url="https://modelo-ur-hermes.openai.azure.com/openai/v1",
)

response = client.responses.create(
    model="IMP-UR-Hermes-GPT5Mini-Coding",
    input="Di únicamente OK"
)

print(response.output_text)
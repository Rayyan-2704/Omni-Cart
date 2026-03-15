import os
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


def generate_recommendation_reason(customer_name: str, product_name: str, category: str) -> str:
    """GPT-4 explains why this product is recommended for this customer."""
    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{
                "role": "system",
                "content": "You are a friendly AI shopping assistant for OmniCart, a Pakistani e-commerce platform. Keep responses concise, helpful, and personalized."
            }, {
                "role": "user",
                "content": (
                    f"In 1-2 sentences, explain why '{product_name}' (category: {category}) "
                    f"is a great recommendation for {customer_name}. Be specific and friendly."
                )
            }],
            max_tokens=100,
            temperature=0.7
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"Recommended based on your shopping preferences and browsing history."


def generate_product_description(product_name: str, category: str, price: float, brand: str = "") -> str:
    """GPT-4 generates a compelling product description for vendors."""
    try:
        response = client.chat.completions.create(
            model="gpt-4",
            messages=[{
                "role": "system",
                "content": "You are a professional e-commerce copywriter for OmniCart. Write compelling, accurate product descriptions that highlight key benefits. Keep it under 3 sentences."
            }, {
                "role": "user",
                "content": (
                    f"Write a product description for: '{product_name}' "
                    f"Brand: {brand or 'Generic'}, Category: {category}, Price: Rs.{price:,.0f}. "
                    f"Make it engaging and highlight key benefits for Pakistani shoppers."
                )
            }],
            max_tokens=150,
            temperature=0.7
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        return f"High quality {product_name} by {brand}. Great value at Rs.{price:,.0f}."

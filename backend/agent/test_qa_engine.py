import unittest

from backend.agent.qa_engine import _extract_keyword_phrase, answer_question


class KeywordExtractionTests(unittest.TestCase):
    def test_extract_ads_keyword_from_contains_question(self):
        self.assertEqual(_extract_keyword_phrase("包含ads的表有哪些"), "ads")

    def test_extract_keyword_with_keyword_phrase(self):
        self.assertEqual(_extract_keyword_phrase("关键词是dwd的表有哪些"), "dwd")

    def test_extract_keyword_with_search_phrase(self):
        self.assertEqual(_extract_keyword_phrase("查找 ods 相关信息的表"), "ods")


class FuzzySearchAnswerTests(unittest.TestCase):
    def test_fuzzy_search_uses_full_ads_keyword(self):
        nodes = [
            {"id": "ads_sales_report", "name": "ads_sales_report", "comment": "ADS 销售报表"},
            {"id": "dwd_sales_detail", "name": "dwd_sales_detail", "comment": "明细表"},
            {"id": "dim_area", "name": "dim_area", "comment": "区域维表"},
        ]
        result = answer_question("包含ads的表有哪些", nodes, [])
        self.assertEqual(result["intent"], "fuzzy_search")
        self.assertIn("包含「ads」相关信息的表", result["answer"])
        self.assertEqual(result["matches"][0]["name"], "ads_sales_report")


if __name__ == "__main__":
    unittest.main()

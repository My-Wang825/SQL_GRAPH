import os
import tempfile
import unittest

from backend.agent.minimax_client import (
    _build_agent_context,
    answer_with_graph_and_files,
)


class AgentContextTests(unittest.TestCase):
    def test_build_agent_context_includes_focus_nodes_and_file_snippets(self):
        with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False, encoding="utf-8") as f:
            f.write(
                "insert into ads_sales_report\n"
                "select * from dwd_sales_detail;\n"
            )
            sql_path = f.name

        try:
            nodes = [
                {
                    "id": "ads_sales_report",
                    "name": "ads_sales_report",
                    "comment": "ADS 销售报表",
                    "filePath": sql_path,
                    "relationCount": 3,
                    "tableType": "junction",
                },
                {
                    "id": "dwd_sales_detail",
                    "name": "dwd_sales_detail",
                    "comment": "销售明细",
                    "filePath": sql_path,
                    "relationCount": 2,
                    "tableType": "core",
                },
            ]
            links = [
                {
                    "source": "dwd_sales_detail",
                    "target": "ads_sales_report",
                    "relationType": "DATA_FLOW",
                    "weight": 1,
                    "sources": [sql_path],
                }
            ]
            context = _build_agent_context("ads 销售报表依赖哪些表", nodes, links)
            focus_ids = [n["id"] for n in context["focus_nodes"]]
            self.assertIn("ads_sales_report", focus_ids)
            self.assertTrue(context["file_snippets"])
            self.assertIn("ads_sales_report", context["file_snippets"][0]["excerpt"])
        finally:
            os.unlink(sql_path)


class AgentFailureTests(unittest.TestCase):
    def test_answer_with_graph_and_files_requires_api_key(self):
        result = answer_with_graph_and_files(
            "ads 表有哪些",
            nodes=[],
            links=[],
            api_key="",
            base_url="https://api.minimax.io/v1",
            model="MiniMax-M2.7",
        )
        self.assertEqual(result["intent"], "agent_answer")
        self.assertIn("MINIMAX_API_KEY", result["answer"])


if __name__ == "__main__":
    unittest.main()

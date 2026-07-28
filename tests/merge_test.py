from app.providers.merge import deep_merge


def test_deep_merge_merges_lists_by_ticker():
    base = {"stockCards": [{"ticker": "SAB", "weight": "30%"}, {"ticker": "VIC", "weight": "25%"}]}
    overlay = {"stockCards": [{"ticker": "SAB", "metrics": [{"label": "P/E", "value": "12.4x"}]}]}

    merged = deep_merge(base, overlay)

    assert len(merged["stockCards"]) == 2
    assert merged["stockCards"][0]["ticker"] == "SAB"
    assert merged["stockCards"][0]["weight"] == "30%"
    assert merged["stockCards"][0]["metrics"][0]["value"] == "12.4x"


if __name__ == "__main__":
    test_deep_merge_merges_lists_by_ticker()
    print("Merge test passed")
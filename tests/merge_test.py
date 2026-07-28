from app.providers.merge import deep_merge

base = {"stockCards": [{"ticker": "SAB", "weight": "30%"}, {"ticker": "VIC", "weight": "25%"}]}
overlay = {"stockCards": [{"ticker": "SAB", "metrics": [{"label": "P/E", "value": "12.4x"}]}]}
merged = deep_merge(base, overlay)
assert len(merged["stockCards"]) == 2
assert merged["stockCards"][0]["ticker"] == "SAB"
assert merged["stockCards"][0]["weight"] == "30%"
assert merged["stockCards"][0]["metrics"][0]["value"] == "12.4x"
print("Merge test passed")

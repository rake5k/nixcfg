# nix-engineer Skill

A NixOS system engineer assistant skill that helps with managing multiple device configurations,
build commands, hardware modules, debugging, and update strategies.

## Performance Metrics

| Metric                      | Value                     |
| --------------------------- | ------------------------- |
| **Pass Rate**               | 100% (15/15 tests passed) |
| **Trigger Accuracy**        | 100% (no false positives) |
| **Response Quality**        | 9.3/10                    |
| **Average Response Length** | 245 words                 |
| **Token Efficiency**        | 98%                       |

## Documentation Files

- `SKILL.md` - Main skill documentation and instructions
- `evaluation-report.html` - Detailed HTML evaluation report with all test cases
- `evaluation-data.json` - JSON data containing all evaluation test cases and results

## Evaluation Report

See [evaluation-report.html](./evaluation-report.html) for:

- Complete test case results (15 evaluations)
- Response quality assessments
- Trigger accuracy analysis
- Full response examples for each test case
- Performance metrics and charts

## Usage Examples

```bash
/nix-engineer acrux              # Get info about acrux device
/nix-engineer all                # List all devices
/nix-engineer update             # Get update strategy advice
/nix-engineer error <message>    # Debug a build error
/nix-engineer nvidia             # Info about NVIDIA module
```

## Files

| File                     | Description                   |
| ------------------------ | ----------------------------- |
| `SKILL.md`               | Main skill documentation      |
| `README.md`              | This file - skill overview    |
| `evaluation-report.html` | Visual HTML evaluation report |
| `evaluation-data.json`   | Test cases and results data   |

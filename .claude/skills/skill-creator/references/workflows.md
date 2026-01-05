# Workflow Patterns

## Sequential Workflows

For tasks with clear step-by-step procedures:

```markdown
## Workflow

1. Analyze input (run analyze.py)
2. Process data
3. Generate output
4. Verify results (run verify.py)
```

Present the roadmap early so Claude understands the full process.

## Conditional Workflows

For tasks with decision points:

```markdown
## Workflow Decision Tree

**Creating new content?**
→ See "Creating" section

**Editing existing content?**
→ See "Editing" section

**Analyzing content?**
→ See "Analysis" section
```

Branch based on user intent or detected conditions.

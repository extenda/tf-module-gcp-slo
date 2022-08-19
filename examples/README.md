# Examples

## Burn rate alerting

All SLOs will have a burn rate alert included, this alert has the following conditions and will go off if any are met.

- 2% of error budget consumed in 1 hour
- 5% of error budget consumed in 6 hours
- 10% of error budget consumed in in 3 days

You can configure this alert by adding `alert:` attribute/input, like the example below.

```yaml
- display_name: Example SLO
  ...
  alert:  
    name: "my-service: High SLO burn rate"
    conditions:
    - name: "2% of error budget consumed in 1 hour"
        threshold_value: 14
        comparison: COMPARISON_GT
        duration: 0s
        time: 3600s
```

If you don’t want an alert you can just leave the alert empty, like the example below.

```yaml
- display_name: Example SLO
  ...
  alert: {}
```

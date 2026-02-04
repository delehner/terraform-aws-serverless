resource "aws_sns_topic" "event" {
  for_each = toset(var.events)

  name                        = "${each.key}-${var.environment}.fifo"
  fifo_topic                  = true
  content_based_deduplication = true

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

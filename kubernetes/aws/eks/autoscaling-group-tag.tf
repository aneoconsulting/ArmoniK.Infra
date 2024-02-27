resource "aws_autoscaling_group_tag" "eks_managed_autoscaling_group_tag" {
  # Create a tuple in a map for each ASG tag combo
  for_each = merge([
    for eks_mng, tags in local.eks_autoscaling_group_tags : {
      for tag_key, tag_value in tags : "${eks_mng}-${substr(tag_key, 25, -1)}" => {
        mng   = eks_mng,
        key   = tag_key,
        value = tag_value
      }
    }
  ]...)
  # Lookup the ASG name for the MNG, error if there is more than one
  autoscaling_group_name = one(module.eks.eks_managed_node_groups[each.value.mng].node_group_autoscaling_group_names)
  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = true
  }
}
/*
resource "aws_autoscaling_group_tag" "self_managed_autoscaling_group_tag" {
  # Create a tuple in a map for each ASG tag combo
  for_each = merge([
    for self_mng, tags in local.self_managed_autoscaling_group_tags : {
      for tag_key, tag_value in tags : "${self_mng}-${substr(tag_key, 25, -1)}" => {
        mng   = self_mng,
        key   = tag_key,
        value = tag_value
      }
    }
  ]...)
  # Lookup the ASG name for the MNG, error if there is more than one
  autoscaling_group_name = one(module.eks.self_managed_node_groups[each.value.mng].autoscaling_group_name)
  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = true
  }
}*/

output "test" {
  value = [ for k,v in merge([
    for self_mng, tags in local.self_managed_autoscaling_group_tags : {
      for tag_key, tag_value in tags : "${self_mng}-${substr(tag_key, 25, -1)}" => {
        mng   = self_mng,
        key   = tag_key,
        value = tag_value
      }
    }
  ]...) : distinct(module.eks.self_managed_node_groups[v.mng].autoscaling_group_name)]
}

output "test_2" {
  value = [ for k,v in merge([
    for self_mng, tags in local.eks_autoscaling_group_tags : {
      for tag_key, tag_value in tags : "${self_mng}-${substr(tag_key, 25, -1)}" => {
        mng   = self_mng,
        key   = tag_key,
        value = tag_value
      }
    }
  ]...) : distinct(module.eks.eks_managed_node_groups[v.mng].node_group_autoscaling_group_names)]
}

import torch
x = torch.rand(10,10)
ixs = torch.randint(10, (2,10))

""" Torch loading checkpoint """
checkpoint = torch.load(checkpoint_path, map_location=device, weights_only=False)

""" Torch Standard Patterns """
# ---Switching out a forward function----
# This may be critical when you are using somebody else code entirely and do not want to 
# mess with their code directly. For example your input does not match expected input
import types
old_forward = model.forward
def wrapped_forward(self, pc):
    colors = torch.zeros_like(pc)  # Extra functionality
    return old_forward(pc, colors)  # Call to the original forward function
model.forward = types.MethodType(wrapped_forward, model)

# ---Mask Filling. Filling a tensor with a certain value given a mask---
# Here is the mask
active_superquadrics = outdict['exist'] > 0.5

# The mask has an extra right most dimension which can be removed
active_mask = active_superquadrics.squeeze(-1).bool()   # (32, 16)

# Make the number of dimensions now same as the matrix to be filled (32, 4096, 16)
active_mask = active_mask.unsqueeze(1)

# Use the masked fill thing
masked_assign_matrix = assign_matrix.masked_fill(
    ~active_mask, float('-inf')
)


# ---- Compute Mask Matrix by expanding a unitary dim -----
_labels = seg_ixs[b]                   # (N)
feats   = point_features[b]            # (N, C)

unique_labels = _labels.unique()

# Compute a mask matrix for the labels. This will allow us to make per label features later
mask = _labels.unsqueeze(0) == unique_labels.unsqueeze(1)  # (U, L)

# Remove labels with no points
valid = mask.any(dim=1)
mask = mask[valid]
unique_labels = unique_labels[valid]
mask = mask.to(feats.device)

# Multiply mask with features to get per part features
masked_feats = feats.unsqueeze(0) * mask.unsqueeze(-1)  # (U, N, C)
counts = mask.sum(dim=1).unsqueeze(-1)     # (U, 1)
embs = masked_feats.sum(dim=1) / counts    # (U, C)


# ---- Compute Intersection Over Union -----
gtl_mask = (gt_label==gtl)
sampled_pred_label = pred_label[gtl_mask]

# Find the highest overlapping prediction
highest_overlapping_pred = torch.mode(sampled_pred_label).values

# compute the IOU
highest_overlapping_pred_mask = pred_label == highest_overlapping_pred

intersection = (gtl_mask & highest_overlapping_pred_mask).sum().float()
union = (gtl_mask | highest_overlapping_pred_mask).sum().float()

iou = intersection/union
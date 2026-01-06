parser = argparse.ArgumentParser(description="Visualize PartNet point clouds colored by PCA of points")
parser.add_argument('--split', default='test', help='Dataset split (train/val/test)')
parser.add_argument('--n', type=int, default=10, help='Number of first examples to visualize (if --examples not set)')
parser.add_argument('--examples', nargs='*', default=None, help='List of CATEGORY/MODEL_ID to visualize explicitly')
parser.add_argument('--out-dir', default=None, help='If set and viser unavailable, saves colored PLYs to this folder')
parser.add_argument('--port', type=int, default=8888, help='Port for viser server')

# Parses arguments which are only known by my paraser. Avoids other arguments that are sent to the script (these are then parsed using compose)
args, hydra_args = parser.parse_known_args()

# Initialize Hydra with a specific config directory
with initialize(version_base=None, config_path="../configs"):
    # hydra_args contains any overrides like 'db=mysql'
    cfg = compose(config_name="align", overrides=hydra_args)
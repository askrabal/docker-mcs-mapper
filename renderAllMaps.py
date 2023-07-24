#!/usr/bin/env python3

from pathlib import Path
from subprocess import run
from sys import path
from argparse import ArgumentParser

path.append("/usr/local/lib/python3/site-packages")

cfg_dir = Path('/home/miner/map_configs')
overviewer = "/usr/local/bin/overviewer.py"
logs_dir = Path("/home/miner/logs/")
logs_dir.mkdir(exist_ok=True)

ap = ArgumentParser()
ap.add_argument("-f", "--forcerender", action="store_true", default=False)
args = ap.parse_args()
for cfg in cfg_dir.iterdir():
    if cfg.is_file() and cfg.suffix == ".py":
        # render maps step
        render_cmd = [overviewer, "--pid", f"/tmp/maps_{cfg.stem}.pid",
                      "--config", f"{cfg.absolute()}"]
        if args.forcerender:
            render_cmd.append("--forcerender")
            print(f"Running a manual --forcerender")
        render_out = logs_dir / f"map_{cfg.stem}.log"
        render_err = logs_dir / f"map_{cfg.stem}.err"
        with render_out.open('a') as fd_out, render_err.open('a') as fd_err:
            run(render_cmd, stdout=fd_out, stderr=fd_err)
        # genpoi step
        genpoi_cmd = [overviewer, "--genpoi", "--config", f"{cfg.absolute()}"]
        genpoi_out = logs_dir / f"poi_{cfg.stem}.log"
        genpoi_err = logs_dir / f"poi_{cfg.stem}.err"
        with genpoi_out.open('a') as fd_out, genpoi_err.open('a') as fd_err:
            run(genpoi_cmd, stdout=fd_out, stderr=fd_err)


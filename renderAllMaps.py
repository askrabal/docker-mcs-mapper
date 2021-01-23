#!/usr/bin/env python3

from pathlib import Path
from subprocess import run

cfg_dir = Path('/home/miner/map_configs')
overviewer = "/usr/local/bin/overviewer.py"
logs_dir = Path("/home/miner/logs/")
logs_dir.mkdir(exist_ok=True)

for cfg in cfg_dir.iterdir():
    if cfg.is_file():
        # read first kB of file for magic processing
        with cfg.open('r') as fd:
            first_k = fd.read(1024)
        # render maps step
        render_cmd = [overviewer, "--pid", f"/tmp/maps_{cfg.stem}.pid",
                      "--config", f"{cfg.absolute()}"]
        render_out = logs_dir / f"map_{cfg.stem}.log"
        render_err = logs_dir / f"map_{cfg.stem}.err"
        with render_out.open('a') as fd_out, render_err.open('a') as fd_err:
            run(render_cmd, stdout=fd_out, stderr=fd_err)
        if "##GENPOI##" not in first_k:
            continue
        # genpoi step
        genpoi_cmd = [overviewer, "--genpoi", "--config", f"{cfg.absolute()}"]
        genpoi_out = logs_dir / f"poi_{cfg.stem}.log"
        genpoi_err = logs_dir / f"poi_{cfg.stem}.err"
        with genpoi_out.open('a') as fd_out, genpoi_err.open('a') as fd_err:
            run(genpoi_cmd, stdout=fd_out, stderr=fd_err)



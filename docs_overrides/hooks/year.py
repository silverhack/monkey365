from datetime import datetime
def on_config(config, **kwargs):
    year: str = str(datetime.now().year)
    config.copyright = config.copyright.format(year=year)

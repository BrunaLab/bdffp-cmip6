import cdsapi

def download_cmip6(experiment, variable, model, path):
    c = cdsapi.Client()
    data = c.retrieve(
      'projections-cmip6',
      {
          'temporal_resolution': 'monthly',
          'experiment': experiment,
          'level': 'single_levels',
          'variable': variable,
          'model': model,
          'ensemble_member': 'r1i1p1',
          'area': [
              0, -65, -5,
              -50,
          ],
          'format': 'zip',
      },
    path
    )
    return data

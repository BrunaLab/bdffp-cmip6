import cdsapi

def download_cmip6(experiment_id, variable_long_name, source_id, path):
    c = cdsapi.Client()
    data = c.retrieve(
      'projections-cmip6',
      {
          'temporal_resolution': 'monthly',
          'experiment': experiment_id,
          'level': 'single_levels',
          'variable': variable_long_name,
          'model': source_id,
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

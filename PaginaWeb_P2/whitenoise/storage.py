from django.contrib.staticfiles.storage import ManifestStaticFilesStorage


class CompressedManifestStaticFilesStorage(ManifestStaticFilesStorage):
    """
    Lightweight stand-in for whitenoise.storage.CompressedManifestStaticFilesStorage.
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

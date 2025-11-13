class WhiteNoiseMiddleware:
    """
    Minimal shim replacement for whitenoise.middleware.WhiteNoiseMiddleware.
    Simply forwards requests without additional static file handling.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        return self.get_response(request)

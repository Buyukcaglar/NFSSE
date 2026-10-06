"""Import the media builder for verification/installation tools."""
import importlib.util
from pathlib import Path


def load_builder():
    spec = importlib.util.spec_from_file_location('language_builder', Path(__file__).with_name('build-language-edition.py'))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

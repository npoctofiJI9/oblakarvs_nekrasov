from django.db import models

class Nombres(models.Model):
    innum = models.IntegerField(unique=True)

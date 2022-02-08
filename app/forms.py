from django import forms
from app.models import Nombres
from django.core.exceptions import ValidationError

class NombresForms(forms.ModelForm):
    
    def clean_innum(self):
        num = self.cleaned_data.get('innum')
        if Nombres.objects.filter(innum=num-1).exists():
            raise ValidationError('Pososi na 1 mensche uzhe est, lox')
        return num

    class Meta:
        model = Nombres
        fields = ('innum',)
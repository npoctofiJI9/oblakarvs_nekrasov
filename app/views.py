from django.views.generic import TemplateView
from app.models import Nombres
from app.forms import NombresForms


class MyView(TemplateView):
    template_name = 'index.html'

    def post(self, request, **kwargs):
        form = NombresForms(request.POST)
        if form.is_valid():
            form.save()
        return super(TemplateView, self).render_to_response({'form':form})

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['form'] = NombresForms()
        return context
<?php

namespace Botble\Quickbooks\Forms;

use Botble\Base\Forms\FormAbstract;
use Botble\Quickbooks\Http\Requests\QuickbooksSettingRequest;

class QuickbooksSettingForm extends FormAbstract
{
    public function buildForm(): void
    {
        $this
            ->setValidatorClass(QuickbooksSettingRequest::class)
            ->withCustomFields()
            ->contentOnly() // Removes header section – optional
            ->add('section_title', 'html', [
                'html' => '<h4>QuickBooks Settings</h4><p>Configure your QuickBooks API details.</p>',
            ])
            ->add('qb_client_id', 'text', [
                'label' => 'QuickBooks Client ID',
                'value' => setting('qb_client_id'),
            ])
            ->add('qb_client_secret', 'text', [
                'label' => 'QuickBooks Client Secret',
                'value' => setting('qb_client_secret'),
            ])
            ->add('qb_redirect_uri', 'text', [
                'label' => 'QuickBooks Redirect URI',
                'value' => setting('qb_redirect_uri'),
            ])
            ->add('submit', 'submit', [
                'label' => trans('core/base::forms.save'),
                'attr' => ['class' => 'btn btn-primary'],
            ]);
    }
}

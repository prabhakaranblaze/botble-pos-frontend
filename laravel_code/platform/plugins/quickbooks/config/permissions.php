<?php
return [
    [
        'name' => 'QuickBooks',
        'flag' => 'quickbooks.index',
    ],
    [
        'name' => 'Settings',
        'flag' => 'quickbooks.setting',
        'parent_flag' => 'quickbooks.index',
    ],
    [
        'name' => 'Crons',
        'flag' => 'quickbooks.cron',
        'parent_flag' => 'quickbooks.index',
    ],
    [
        'name' => 'Create Sales Receipt',
        'flag' => 'quickbooks.salesreceipt',
        'parent_flag' => 'quickbooks.cron',
    ],
    [
        'name' => 'Products',
        'flag' => 'quickbooks.product',
        'parent_flag' => 'quickbooks.index',
    ],
    [
        'name' => 'Import Products',
        'flag' => 'quickbooks.productimport',
        'parent_flag' => 'quickbooks.product',
    ],
    [
        'name' => 'Categories',
        'flag' => 'quickbooks.category',
        'parent_flag' => 'quickbooks.index',
    ],
    [
        'name' => 'Import Categories',
        'flag' => 'quickbooks.categoryimport',
        'parent_flag' => 'quickbooks.category',
    ],
    [
        'name' => 'Accounts',
        'flag' => 'quickbooks.account',
        'parent_flag' => 'quickbooks.index',
    ],
];
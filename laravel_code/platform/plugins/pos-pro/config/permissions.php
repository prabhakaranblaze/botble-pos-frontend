<?php

return [
    [
        'name' => 'POS Pro',
        'flag' => 'pos-pro',
    ],
    [
        'name' => 'POS',
        'flag' => 'pos.index',
        'parent_flag' => 'pos-pro',
    ],
    [
        'name' => 'Reports',
        'flag' => 'pos.reports',
        'parent_flag' => 'pos-pro',
    ],
    [
        'name' => 'Settings',
        'flag' => 'pos.settings',
        'parent_flag' => 'pos-pro',
    ],
    [
        'name' => 'Devices',
        'flag' => 'pos.devices',
        'parent_flag' => 'pos-pro',
    ],
    [
        'name' => 'Registers',
        'flag' => 'pos.registers',
        'parent_flag' => 'pos-pro',
    ],
    [
        'name' => 'Orders',
        'flag' => 'pos.orders',
        'parent_flag' => 'pos-pro',
    ],
];

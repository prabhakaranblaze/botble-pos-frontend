<?php

namespace Botble\PosPro\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class SeedDenominationsCommand extends Command
{
    protected $signature = 'pos-pro:seed-denominations';

    protected $description = 'Seed denominations for POS Pro (USD and INR)';

    public function handle(): int
    {
        $this->info('Seeding denominations for POS Pro...');

        try {
            // Check if already seeded
            $count = DB::table('pos_denominations')->count();
            
            if ($count > 0) {
                $this->warn("Denominations already exist ({$count} records found).");
                
                if (!$this->confirm('Do you want to reseed (this will delete existing denominations)?')) {
                    $this->info('Seeding cancelled.');
                    return self::SUCCESS;
                }
                
                DB::table('pos_denominations')->truncate();
                $this->info('Existing denominations cleared.');
            }

            DB::beginTransaction();

            $denominations = [
                // USD - United States Dollar
                ['currency_code' => 'USD', 'value' => 0.01, 'type' => 'coin', 'label' => '1 cent', 'sort_order' => 1],
                ['currency_code' => 'USD', 'value' => 0.05, 'type' => 'coin', 'label' => '5 cents (Nickel)', 'sort_order' => 2],
                ['currency_code' => 'USD', 'value' => 0.10, 'type' => 'coin', 'label' => '10 cents (Dime)', 'sort_order' => 3],
                ['currency_code' => 'USD', 'value' => 0.25, 'type' => 'coin', 'label' => '25 cents (Quarter)', 'sort_order' => 4],
                ['currency_code' => 'USD', 'value' => 1.00, 'type' => 'note', 'label' => '$1', 'sort_order' => 5],
                ['currency_code' => 'USD', 'value' => 5.00, 'type' => 'note', 'label' => '$5', 'sort_order' => 6],
                ['currency_code' => 'USD', 'value' => 10.00, 'type' => 'note', 'label' => '$10', 'sort_order' => 7],
                ['currency_code' => 'USD', 'value' => 20.00, 'type' => 'note', 'label' => '$20', 'sort_order' => 8],
                ['currency_code' => 'USD', 'value' => 50.00, 'type' => 'note', 'label' => '$50', 'sort_order' => 9],
                ['currency_code' => 'USD', 'value' => 100.00, 'type' => 'note', 'label' => '$100', 'sort_order' => 10],

                // INR - Indian Rupee
                ['currency_code' => 'INR', 'value' => 1.00, 'type' => 'coin', 'label' => '₹1', 'sort_order' => 1],
                ['currency_code' => 'INR', 'value' => 2.00, 'type' => 'coin', 'label' => '₹2', 'sort_order' => 2],
                ['currency_code' => 'INR', 'value' => 5.00, 'type' => 'coin', 'label' => '₹5', 'sort_order' => 3],
                ['currency_code' => 'INR', 'value' => 10.00, 'type' => 'coin', 'label' => '₹10', 'sort_order' => 4],
                ['currency_code' => 'INR', 'value' => 20.00, 'type' => 'note', 'label' => '₹20', 'sort_order' => 5],
                ['currency_code' => 'INR', 'value' => 50.00, 'type' => 'note', 'label' => '₹50', 'sort_order' => 6],
                ['currency_code' => 'INR', 'value' => 100.00, 'type' => 'note', 'label' => '₹100', 'sort_order' => 7],
                ['currency_code' => 'INR', 'value' => 200.00, 'type' => 'note', 'label' => '₹200', 'sort_order' => 8],
                ['currency_code' => 'INR', 'value' => 500.00, 'type' => 'note', 'label' => '₹500', 'sort_order' => 9],
                ['currency_code' => 'INR', 'value' => 2000.00, 'type' => 'note', 'label' => '₹2000', 'sort_order' => 10],
            ];

            foreach ($denominations as $denomination) {
                DB::table('pos_denominations')->insert(array_merge($denomination, [
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]));
            }

            DB::commit();

            $this->info('Successfully seeded ' . count($denominations) . ' denominations!');
            $this->info('- USD: 10 denominations');
            $this->info('- INR: 10 denominations');

            return self::SUCCESS;
        } catch (Throwable $exception) {
            DB::rollBack();

            $this->error('Error seeding denominations: ' . $exception->getMessage());

            return self::FAILURE;
        }
    }
}
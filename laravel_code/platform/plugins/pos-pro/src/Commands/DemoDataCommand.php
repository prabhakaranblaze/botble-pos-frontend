<?php

namespace Botble\PosPro\Commands;

use Botble\PosPro\Database\Seeders\DemoSeeder;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class DemoDataCommand extends Command
{
    protected $signature = 'pos-pro:demo';

    protected $description = 'Generate demo data for POS Pro plugin';

    public function handle(): int
    {
        $this->components->info('Generating demo data for POS Pro...');

        try {
            DB::beginTransaction();

            $this->call('db:seed', [
                '--class' => DemoSeeder::class,
            ]);

            DB::commit();

            $this->info('Demo data generated successfully!');

            return self::SUCCESS;
        } catch (Throwable $exception) {
            DB::rollBack();

            $this->error('Error generating demo data: ' . $exception->getMessage());

            return self::FAILURE;
        }
    }
}

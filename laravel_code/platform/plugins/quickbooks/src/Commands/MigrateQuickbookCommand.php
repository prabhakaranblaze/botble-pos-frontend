<?php

namespace Botble\Quickbooks\Commands;

use Botble\Quickbooks\Facades\Quickbooks;
use Illuminate\Console\Command;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Input\InputOption;

#[AsCommand('cms:quickbooks:migrate', 'Migrate quickbooks columns to table')]
class MigrateQuickbookCommand extends Command
{
    public function handle(): int
    {
        $className = str_replace('/', '\\', $this->option('class'));
        $error = true;

        if (! $className) {
            foreach (Quickbooks::supportedModels() as $className) {
                $this->runSchema($className);
                $error = false;
            }
        } elseif (Quickbooks::isSupported($className)) {
            $this->runSchema($className);
            $error = false;
        }

        if ($error) {
            $this->components->error('Not supported model');

            return self::FAILURE;
        }

        $this->components->info('Migrate quickbooks successfully!');

        return self::SUCCESS;
    }

    public function runSchema(string $className): void
    {
        $model = new $className();
        Schema::connection($model->getConnectionName())->table(
            $model->getTable(),
            function (Blueprint $table) use ($className): void {
                $table->quickbooks($className);
            }
        );
    }

    protected function configure(): void
    {
        $this->addOption('class', null, InputOption::VALUE_REQUIRED, 'The model class name');
    }
}

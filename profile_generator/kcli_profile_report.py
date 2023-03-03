import click
import yaml
from jinja2 import Template


@click.group()
def cli():
    pass

@click.command()
@click.option('--input', '-i', help='Path to input file', type=click.Path(exists=True), default='kcli-profiles.yml')
@click.option('--output', '-o', help='Path to output file', type=click.Path(), default='kcli-profiles.html')
@click.option('--passwords/--no-passwords', help='Hide passwords', default=True)
@click.option('--console/--no-console', help='Print to console', default=False)
@click.option('--help', '-h', is_flag=True, help='Display help message')
def generate_html_report(input, output, passwords, console, help):

    if help:
        click.echo(click.get_current_context().get_help())
        return
    
    with open(input, 'r') as f:
        data = yaml.safe_load(f)

    template = Template('''<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta http-equiv="X-UA-Compatible" content="ie=edge">
        <title>kcli-profiles Report</title>
        <!-- Bootstrap CSS -->
        <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
    </head>
    <body>
        <div class="container">
        <h1 class="text-center">kcli-profiles Report</h1>
        <table class="table bg-light">
            <thead>
            <tr>
                <th>Operating System</th>
                <th>Image</th>
                <th>Num CPUs</th>
                <th>Memory</th>
                <th>Networks</th>
                <th>Reserve DNS</th>
                <th>Disks</th>
                <th>Commands</th>
            </tr>
            </thead>
            <tbody>
            {% for os_name, os_data in data.items() %}
            <tr>
                <td>{{ os_name }}</td>
                <td>{{ os_data["image"] }}</td>
                <td>{{ os_data["numcpus"] }}</td>
                <td>{{ os_data["memory"] }}</td>
                <td>
                <ul class="list-group list-group-flush">
                    {% for net in os_data['nets'] %}
                    <li class="list-group-item">{{ net['name'] }}</li>
                    {% endfor %}
                </ul>
                </td>
                <td>{{ os_data["reservedns"] }}</td>
                <td>
                <ul class="list-group list-group-flush">
                    {% for disk in os_data['disks'] %}
                    <li class="list-group-item">{{ disk['size'] }}</li>
                    {% endfor %}
                </ul>
                </td>
                <td>
                <ul class="list-group list-group-flush">
                    {% for cmd in os_data['cmds'] %}
                    {% if passwords and 'password' in cmd %}
                    <li class="list-group-item">{{ cmd.split('|')[0] }}|********</li>
                    {% else %}
                    <li class="list-group-item">{{ cmd }}</li>
                    {% endif %}
                    {% endfor %}
                </ul>
                </td>
            </tr>
            {% endfor %}
            </tbody>
        </table>
        </div>
    </body>
    </html>''')

    report = template.render(data=data, passwords=passwords)

    with open(output, 'w') as f:
        f.write(report)

    if console:
        click.echo(report)

    print(f'Successfully generated report to {output}')

if __name__ == '__main__':
    generate_html_report()  # call the click CLI function

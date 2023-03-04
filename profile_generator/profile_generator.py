import click
import yaml
from jinja2 import Template
import os.path

@click.group()
def cli():
    pass

@cli.command()
@click.argument('os_name')
@click.argument('template_path', type=click.Path(exists=True))
@click.option('--image', help='Image name', required=True)
@click.option('--rhnregister', help='Enable RHN registration', type=bool, default=False)
@click.option('--rhnorg', help='RHN organization', default='')
@click.option('--rhnactivationkey', help='RHN activation key', default='')
@click.option('--numcpus', help='Number of CPUs', type=int, default=2)
@click.option('--memory', help='Memory size in MB', type=int, default=4096)
@click.option('--disk-size', help='Disk size in GB', type=int, default=20)
@click.option('--reservedns', help='Reserve DNS name', type=bool, default=False)
@click.option('--net-name', help='Network name', default='qubinet')
@click.option('--user', help='User name', required=True)
@click.option('--user-password', help='User password', required=True)
@click.option('--offline-token', help='Offline token', default='')
@click.option('--help', '-h', is_flag=True, help='Display help message')
def update_yaml(os_name, template_path, image, rhnregister, rhnorg, rhnactivationkey, numcpus, memory, disk_size,
                reservedns, net_name, user, user_password, offline_token, help):

    if help:
        click.echo(click.get_current_context().get_help())
        return

    if not os.path.isfile('kcli-profiles.yml'):
        open('kcli-profiles.yml', 'w').close()

    with open('kcli-profiles.yml', 'r') as f:
        data = yaml.safe_load(f) or {}

    with open(template_path, 'r') as f:
        template_data = f.read()

    template = Template(template_data)
    data[os_name] = yaml.load(template.render(
        os_name=os_name,
        image=image,
        rhnregister=rhnregister,
        rhnorg=rhnorg,
        rhnactivationkey=rhnactivationkey,
        numcpus=numcpus,
        memory=memory,
        disk_size=disk_size,
        reservedns=reservedns,
        net_name=net_name,
        user=user,
        user_password=user_password,
        offline_token=offline_token,
    ), Loader=yaml.SafeLoader)

    with open('kcli-profiles.yml', 'w') as f:
        yaml.dump(data, f)

    print(f'Successfully updated {os_name} entry in kcli-profiles.yml')

if __name__ == '__main__':
    cli()

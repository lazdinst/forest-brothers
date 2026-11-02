import bpy, math, json, sys
from pathlib import Path
from mathutils import Quaternion, Vector

ROOT=Path(r'C:\Users\Nauda\Documents\Codex\ForestBrothers-Art')
RES=ROOT/'enemy-source-resources'
OUT=Path(r'C:\Users\Nauda\Code\forest-brothers\assets\characters\mpfb_enemy')
OUT.mkdir(parents=True,exist_ok=True)
if 'bl_ext.blender_org.mpfb' not in bpy.context.preferences.addons:
    bpy.ops.preferences.addon_enable(module='bl_ext.blender_org.mpfb')
from bl_ext.blender_org.mpfb.services import HumanService
body=bpy.data.objects['Human']; rig=body.find_armature()
assert rig and len(rig.data.bones)==53

def images_in(tree,visited=None):
    visited=visited or set()
    if tree in visited:return []
    visited.add(tree); result=[]
    for n in tree.nodes:
        if n.type=='TEX_IMAGE' and n.image:result.append(n.image)
        if n.type=='GROUP' and n.node_tree:result+=images_in(n.node_tree,visited)
    return result
skin_images=images_in(body.data.materials[0].node_tree)
skin=next(im for im in skin_images if 'Jartur' in im.name)

def simple_material(obj,name,image=None,tint=(1,1,1,1),alpha=False):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    bsdf=mat.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value=tint
    bsdf.inputs['Roughness'].default_value=0.88
    if image:
        tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
        mat.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
        if alpha:
            mat.node_tree.links.new(tex.outputs['Alpha'],bsdf.inputs['Alpha'])
            mat.surface_render_method='DITHERED'
    obj.data.materials.clear();obj.data.materials.append(mat)
    return mat
simple_material(body,'Skin',skin)
def image_from_mhmat(path):
    for line in path.read_text(encoding='utf-8-sig').splitlines():
        fields=line.strip().split(maxsplit=1)
        if len(fields)==2 and fields[0]=='diffuseTexture':
            return bpy.data.images.load(str((path.parent/fields[1]).resolve()),check_existing=True)
    return None
parts=[]
specs=[
 ('Shirt','clothes/toigo_fisherman_sweater/toigo_fisherman_sweater.mhclo','Clothes','clothes/toigo_fisherman_sweater/sweater_fisherman.mhmat'),
 ('Trousers','clothes/toigo_wool_pants/toigo_wool_pants.mhclo','Clothes','clothes/toigo_wool_pants/pants_wool.mhmat'),
 ('Boots','clothes/toigo_ankle_boots_male/toigo_ankle_boots_male.mhclo','Clothes','clothes/toigo_ankle_boots_male/boots_ankle_male.mhmat'),
 ('Eyes','eyes/low-poly/low-poly.mhclo','Eyes','eyes/materials/brown.mhmat'),
 ('Hair','hair/short02/short02.mhclo','Hair','hair/short02/short02.mhmat'),
]
for name,mhclo,kind,mhmat in specs:
    bpy.context.view_layer.objects.active=body
    part=HumanService.add_mhclo_asset(str(RES/mhclo),body,asset_type=kind,subdiv_levels=0,material_type='GAMEENGINE')
    part.name=name
    simple_material(part,name+'Material',image_from_mhmat(RES/mhmat),alpha=name=='Hair')
    assert part.find_armature()==rig,name
    parts.append(part)
body.name='Body'
for obj in [body]+parts:
    for poly in obj.data.polygons:poly.use_smooth=True

# Keep the editable dressed source, including MPFB fitting metadata and masks.
bpy.ops.file.pack_all()
source=ROOT/'characters/working/forest_brothers_enemy_dressed_v1.blend'
bpy.ops.wm.save_as_mainfile(filepath=str(source),copy=True)

# Bake fitted shapes, hidden helpers and clothing coverage in an export copy.
# Armature modifiers remain live and all garments remain separate objects.
for obj in [body]+parts:
    modifiers=list(obj.modifiers)
    for m in modifiers:
        if m.type=='ARMATURE':m.show_viewport=False;m.show_render=False
    bpy.context.view_layer.update()
    dg=bpy.context.evaluated_depsgraph_get()
    mesh=bpy.data.meshes.new_from_object(obj.evaluated_get(dg),preserve_all_data_layers=True,depsgraph=dg)
    obj.data=mesh
    for m in list(obj.modifiers):obj.modifiers.remove(m)
    mod=obj.modifiers.new('SharedRig','ARMATURE');mod.object=rig
    obj.parent=rig

axis={'x':Vector((1,0,0)),'y':Vector((0,1,0)),'z':Vector((0,0,1))}
def turn(name,world_axis,angle):
    b=rig.pose.bones[name]
    rest=b.bone.matrix_local.to_quaternion()
    q=rest.inverted() @ Quaternion(axis[world_axis],angle) @ rest
    b.rotation_quaternion=b.rotation_quaternion @ q
def clear():
    for b in rig.pose.bones:
        b.rotation_mode='QUATERNION';b.rotation_quaternion=(1,0,0,0);b.location=(0,0,0);b.scale=(1,1,1)
def pose(kind,t):
    clear()
    # Lower A-pose arms into a relaxed standing pose.
    turn('upperarm_l','y',0.65);turn('upperarm_r','y',-0.65)
    turn('lowerarm_l','x',-0.1);turn('lowerarm_r','x',-0.1)
    if kind in ('idle','aim'):
        turn('spine_02','x',math.sin(t*math.tau)*0.012)
    if kind=='walk':
        s=math.sin(t*math.tau)
        for side,phase in [('l',s),('r',-s)]:
            turn('thigh_'+side,'x',0.32*phase)
            turn('calf_'+side,'x',-max(0,phase)*0.42)
            turn('upperarm_'+side,'x',-0.16*phase)
        rig.pose.bones['Root'].location.z=abs(s)*0.014
    if kind=='aim':
        turn('upperarm_l','x',-1.12);turn('upperarm_r','x',-1.12)
        turn('lowerarm_l','x',-0.5);turn('lowerarm_r','x',-0.5)
    if kind=='die':
        p=t*t*(3-2*t)
        turn('Root','x',p*math.pi/2)
        rig.pose.bones['Root'].location.z=0.24*p
        turn('upperarm_l','y',-0.3*p);turn('upperarm_r','y',0.3*p)
        turn('calf_l','x',-0.3*math.sin(t*math.pi))

rig.animation_data_create()
for kind,seconds in [('idle',2.4),('walk',1.0),('aim',2.4),('die',0.95)]:
    action=bpy.data.actions.new(kind);rig.animation_data.action=action
    steps=24;end=round(seconds*24)
    for i in range(steps+1):
        frame=1+end*i/steps
        pose(kind,i/steps)
        for b in rig.pose.bones:
            b.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=b.name)
            b.keyframe_insert(data_path='location',frame=frame,group=b.name)
    track=rig.animation_data.nla_tracks.new();track.name=kind
    track.strips.new(kind,1,action)
rig.animation_data.action=None
for track in rig.animation_data.nla_tracks:track.mute=True
clear()
bpy.context.scene.frame_set(1)
bpy.ops.object.select_all(action='DESELECT')
for obj in [rig,body]+parts:obj.select_set(True)
bpy.context.view_layer.objects.active=rig
bpy.context.scene.render.fps=24
path=OUT/'enemy_v1.glb'
bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='ACTIONS',export_frame_range=False,export_force_sampling=True,export_skins=True,export_morph=False,export_materials='EXPORT',export_yup=True)
report={'source':str(source),'glb':str(path),'skin_image':skin.name,'rig':'MPFB game_engine','bone_count':len(rig.data.bones),'parts':[o.name for o in [body]+parts],'clips':['idle','walk','aim','die'],'meshes':[]}
for obj in [body]+parts:
    obj.data.calc_loop_triangles()
    report['meshes'].append({'name':obj.name,'vertices':len(obj.data.vertices),'triangles':len(obj.data.loop_triangles),'bound':obj.find_armature()==rig})
(OUT/'build-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('ENEMY_BUILD '+json.dumps(report))
